# frozen_string_literal: true

# Open and close versions
class VersionService
  def self.open(work, opts = {})
    new(work).open(opts)
  end

  def self.can_open?(work, opts = {})
    new(work).can_open?(opts)
  end

  def self.open?(work)
    new(work).open_for_versioning?
  end

  def self.close(work, opts = {})
    new(work).close(opts)
  end

  def initialize(work)
    @work = work
  end

  # Increments the version number and initializes versioningWF for the object
  # @param [Hash] opts optional params
  # @option opts [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  # @option opts [String] :significance set significance (major/minor/patch) of version change
  # @option opts [String] :description set description of version change
  # @option opts [String] :opening_user_name add opening username to the events datastream
  # @raise [Dor::Exception] if the object hasn't been accessioned, or if a version is already opened
  def open(opts = {})
    sdr_version = try_to_get_current_version(opts[:assume_accessioned])

    vmd_ds = work.versionMetadata
    vmd_ds.sync_then_increment_version sdr_version
    vmd_ds.save unless work.new_record?

    Dor::Config.workflow.client.create_workflow_by_name(work.pid, 'versioningWF')

    return if (opts.keys & open_options_requiring_work_save).empty?

    work.events.add_event('open', opts[:opening_user_name], "Version #{vmd_ds.current_version_id} opened") if opts[:opening_user_name]

    vmd_ds.update_current_version(description: opts[:description], significance: opts[:significance].to_sym) if opts[:description] && opts[:significance]

    work.save!
  end

  # Determines whether a new version can be opened for an object.
  # @param [Hash] opts optional params
  # @option opts [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  # @return [Boolean] true if a new version can be opened.
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
  # @option opts [Boolean] :start_accesion set to true if you want accessioning to start (default), false otherwise
  # @raise [Dor::Exception] if the object hasn't been opened for versioning, or if accessionWF has
  #   already been instantiated or the current version is missing a tag or description
  def close(opts = {})
    unless opts.empty?
      work.versionMetadata.update_current_version(description: opts[:description], significance: opts[:significance].to_sym) if opts[:description] && opts[:significance]

      work.versionMetadata.save
    end

    raise Dor::Exception, "latest version in versionMetadata for #{work.pid} requires tag and description before it can be closed" unless work.versionMetadata.current_version_closeable?
    raise Dor::Exception, "Trying to close version on #{work.pid} which is not opened for versioning" unless open_for_versioning?
    raise Dor::Exception, "accessionWF already created for versioned object #{work.pid}" if accessioning?

    Dor::Config.workflow.client.close_version 'dor', work.pid, opts.fetch(:start_accession, true) # Default to creating accessionWF when calling close_version
    work.events.add_event('close', opts[:user_name], "Version #{work.current_version} closed") if opts[:user_name]
    work.save!
  end

  # Performs checks on whether a new version can be opened for an object
  # @return [Integer] the version from sdr-services-app if a version can be opened
  # @param [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  # @raise [Dor::Exception] if the object hasn't been accessioned, if a version is already opened,
  #                         or if SDR app returns 404 when queried.
  #
  def try_to_get_current_version(assume_accessioned = false)
    # Raised when the object has never been accessioned.
    # The accessioned milestone is the last step of the accessionWF.
    # During local development, we need a way to open a new version even if the object has not been accessioned.
    raise(Dor::Exception, 'Object net yet accessioned') unless
        assume_accessioned || Dor::Config.workflow.client.lifecycle('dor', work.pid, 'accessioned')
    # Raised when the current version has any incomplete wf steps and there is a versionWF.
    # The open milestone is part of the versioningWF.
    raise Dor::VersionAlreadyOpenError, 'Object already opened for versioning' if open_for_versioning?
    # Raised when the current version has any incomplete wf steps and there is an accessionWF.
    # The submitted milestone is part of the accessionWF.
    raise Dor::Exception, 'Object currently being accessioned' if accessioning?

    SdrClient.current_version work.pid
  end

  # Checks if current version has any incomplete wf steps and there is a versionWF
  # @return [Boolean] true if object is open for versioning
  def open_for_versioning?
    return true if Dor::Config.workflow.client.active_lifecycle('dor', work.pid, 'opened')

    false
  end

  # Checks if the current version has any incomplete wf steps and there is an accessionWF.
  # @return [Boolean] true if object is currently being accessioned
  def accessioning?
    return true if Dor::Config.workflow.client.active_lifecycle('dor', work.pid, 'submitted')

    false
  end

  attr_reader :work

  private

  def open_options_requiring_work_save
    [:opening_user_name, :significance, :description]
  end
end
