# frozen_string_literal: true

# Open and close versions
class VersionService
  def self.open(work, opts = {}, event_factory:)
    new(work, event_factory: event_factory).open(opts)
  end

  def self.can_open?(work, opts = {})
    new(work).can_open?(opts)
  end

  def self.open?(work)
    new(work).open_for_versioning?
  end

  def self.close(work, opts = {}, event_factory:)
    new(work, event_factory: event_factory).close(opts)
  end

  def initialize(work, event_factory: nil)
    @work = work
    @event_factory = event_factory
  end

  # Increments the version number and initializes versioningWF for the object
  # @param [Hash] opts optional params
  # @option opts [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  # @option opts [String] :significance set significance (major/minor/patch) of version change
  # @option opts [String] :description set description of version change
  # @option opts [String] :opening_user_name add opening username to the events datastream
  # @raise [Dor::Exception] if the object hasn't been accessioned, or if a version is already opened
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def open(opts = {})
    sdr_version = try_to_get_current_version(opts[:assume_accessioned])

    vmd_ds = work.versionMetadata
    vmd_ds.sync_then_increment_version sdr_version
    vmd_ds.save unless work.new_record?

    workflow_client.create_workflow_by_name(work.pid, 'versioningWF', version: work.current_version)

    return if (opts.keys & open_options_requiring_work_save).empty?

    work.events.add_event('open', opts[:opening_user_name], "Version #{vmd_ds.current_version_id} opened") if opts[:opening_user_name]

    vmd_ds.update_current_version(description: opts[:description], significance: opts[:significance].to_sym) if opts[:description] && opts[:significance]

    work.save!
    event_factory.create(druid: work.pid, event_type: 'version_open', data: { who: opts[:opening_user_name], version: work.current_version })
  end

  # Determines whether a new version can be opened for an object.
  # @param [Hash] opts optional params
  # @option opts [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  # @return [Boolean] true if a new version can be opened.
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def can_open?(opts = {})
    try_to_get_current_version(opts[:assume_accessioned])
    true
  rescue Dor::Exception
    false
  end

  # Sets versioningWF:submit-version to completed and initiates accessionWF for the object
  # @param [Hash] opts optional params
  # @option opts [String] :description describes the version change
  # @option opts [Symbol] :significance which part of the version tag to increment
  #  :major, :minor, :admin (see Dor::VersionTag#increment)
  # @option opts [String] :version_num version number to archive rows with. Otherwise, current version is used
  # @option opts [String] :user_name add username to the events datastream
  # @option opts [Boolean] :start_accession set to true if you want accessioning to start (default), false otherwise
  # @raise [Dor::Exception] if the object hasn't been opened for versioning, or if accessionWF has
  #   already been instantiated or the current version is missing a tag or description
  def close(opts = {})
    unless opts.empty?
      work.versionMetadata.update_current_version(description: opts[:description], significance: opts[:significance].to_sym) if opts[:description] && opts[:significance]

      work.versionMetadata.save
    end

    raise Dor::Exception, "latest version in versionMetadata for #{work.pid} requires tag and description before it can be closed" unless work.versionMetadata.current_version_closeable?
    raise Dor::Exception, "Trying to close version on #{work.pid} which is not opened for versioning" unless open_for_versioning?
    raise Dor::Exception, "Trying to close version on #{work.pid} which has active assemblyWF" if active_assembly_wf?
    raise Dor::Exception, "accessionWF already created for versioned object #{work.pid}" if accessioning?

    # Default to creating accessionWF when calling close_version
    create_accession_wf = opts.fetch(:start_accession, true)
    workflow_client.close_version(repo: 'dor',
                                  druid: work.pid,
                                  version: work.current_version,
                                  create_accession_wf: create_accession_wf)
    work.events.add_event('close', opts[:user_name], "Version #{work.current_version} closed") if opts[:user_name]
    work.save!
    event_factory.create(druid: work.pid, event_type: 'version_close', data: { who: opts[:user_name], version: work.current_version })
  end

  # Performs checks on whether a new version can be opened for an object
  # @return [Integer] the version from Preservation (SDR) if a version can be opened
  # @param [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  # @raise [Dor::Exception, Preservation::Client::NotFoundError] if the object hasn't been accessioned,
  #    if a version is already opened, or if Preservation returns 404 when queried.
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def try_to_get_current_version(assume_accessioned = false)
    # Raised when the object has never been accessioned.
    # The accessioned milestone is the last step of the accessionWF.
    # During local development, we need a way to open a new version even if the object has not been accessioned.
    raise(Dor::Exception, 'Object net yet accessioned') unless
        assume_accessioned || workflow_client.lifecycle('dor', work.pid, 'accessioned')
    # Raised when the current version has any incomplete wf steps and there is a versionWF.
    # The open milestone is part of the versioningWF.
    raise Dor::VersionAlreadyOpenError, 'Object already opened for versioning' if open_for_versioning?
    # Raised when the current version has any incomplete wf steps and there is an accessionWF.
    # The submitted milestone is part of the accessionWF.
    raise Dor::Exception, 'Object currently being accessioned' if accessioning?

    Preservation::Client.objects.current_version(work.pid)
  rescue Preservation::Client::NotFoundError
    raise Dor::Exception, 'Preservation (SDR) is not yet answering queries about this object. ' \
      "When an object has just been transferred, Preservation isn't immediately ready to answer queries."
  end

  # Checks if current version has any incomplete wf steps and there is a versionWF
  # @return [Boolean] true if object is open for versioning
  def open_for_versioning?
    return true if workflow_client.active_lifecycle('dor', work.pid, 'opened', version: work.current_version)

    false
  end

  # Checks if the current version has any incomplete wf steps and there is an accessionWF.
  # @return [Boolean] true if object is currently being accessioned
  def accessioning?
    return true if workflow_client.active_lifecycle('dor', work.pid, 'submitted', version: work.current_version)

    false
  end

  attr_reader :work, :event_factory

  private

  def open_options_requiring_work_save
    [:opening_user_name, :significance, :description]
  end

  def active_assembly_wf?
    return true if workflow_client.workflow_status(druid: work.pid, version: work.current_version, workflow: 'assemblyWF', process: 'accessioning-initiate') == 'waiting'
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
