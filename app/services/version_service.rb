# frozen_string_literal: true

# Open and close versions
class VersionService
  # @param [String] :significance set significance (major/minor/patch) of version change
  # @param [String] :description set description of version change
  # @param [String] :opening_user_name add opening username to the events datastream
  # @param [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  def self.open(cocina_object, event_factory:, description:, significance:, opening_user_name: nil, assume_accessioned: false)
    new(cocina_object, event_factory: event_factory).open(description: description,
                                                          significance: significance,
                                                          opening_user_name: opening_user_name,
                                                          assume_accessioned: assume_accessioned)
  end

  # @param [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  def self.can_open?(cocina_object, assume_accessioned: false)
    new(cocina_object).can_open?(assume_accessioned: assume_accessioned)
  end

  def self.open?(cocina_object)
    new(cocina_object).open_for_versioning?
  end

  # @param [String] :description describes the version change
  # @param [Symbol] :significance which part of the version tag to increment
  #  :major, :minor, :admin (see Dor::VersionTag#increment)
  # @param [String] :user_name add username to the events datastream
  # @param [Boolean] :start_accession set to true if you want accessioning to start (default), false otherwise
  def self.close(cocina_object, event_factory:, description: nil, significance: nil, user_name: nil, start_accession: true)
    new(cocina_object, event_factory: event_factory).close(description: description,
                                                           significance: significance,
                                                           user_name: user_name,
                                                           start_accession: start_accession)
  end

  def self.in_accessioning?(cocina_object)
    new(cocina_object).accessioning?
  end

  def initialize(cocina_object, event_factory: nil)
    @cocina_object = cocina_object
    @event_factory = event_factory
  end

  # Increments the version number and initializes versioningWF for the object
  # @param [String] :significance set significance (major/minor/patch) of version change
  # @param [String] :description set description of version change
  # @param [String] :opening_user_name add opening username to the events datastream
  # @param [Boolean] :assume_accessioned If true, does not check whether object has been accessioned.
  # @return [Cocina::Models::DRO, Cocina::Models::AdminPolicy, Cocina::Models::Collection] updated cocina object
  # @raise [Dor::Exception] if the object hasn't been accessioned, or if a version is already opened
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def open(significance:, description:, opening_user_name:, assume_accessioned:)
    # This can be removed after migration.
    VersionMigrationService.find_and_migrate(druid)
    raise ArgumentError, 'description and significance are required to open a new version' if description.blank? || significance.blank?

    ensure_openable!(assume_accessioned: assume_accessioned)
    if Settings.version_service.sync_with_preservation
      sdr_version = retrieve_version_from_preservation
      new_object_version = ObjectVersion.sync_then_increment_version(druid, sdr_version)
    else
      # This is for testing when we don't have the SDR container available
      new_object_version = ObjectVersion.increment_version(druid)
    end
    update_cocina_object = cocina_object
    update_cocina_object = CocinaObjectStore.save(cocina_object.new(version: new_object_version.version)) if cocina_object.version != new_object_version.version

    workflow_client.create_workflow_by_name(druid, 'versioningWF', version: new_object_version.version.to_s)

    ObjectVersion.update_current_version(druid, description: description, significance: significance.to_sym) if description || significance

    event_factory.create(druid: druid, event_type: 'version_open', data: { who: opening_user_name, version: new_object_version.version.to_s })
    update_cocina_object
  end

  # Determines whether a new version can be opened for an object.
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  # @return [Boolean] true if a new version can be opened.
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def can_open?(assume_accessioned: false)
    ensure_openable!(assume_accessioned: assume_accessioned)
    retrieve_version_from_preservation
    true
  rescue Dor::Exception
    false
  end

  # Sets versioningWF:submit-version to completed and initiates accessionWF for the object
  # @param [String] :description describes the version change
  # @param [Symbol] :significance which part of the version tag to increment
  #  :major, :minor, :admin (see Dor::VersionTag#increment)
  # @param [String] :user_name add username to the events datastream
  # @param [Boolean] :start_accession set to true if you want accessioning to start (default), false otherwise
  # @raise [Dor::Exception] if the object hasn't been opened for versioning, or if accessionWF has
  #   already been instantiated or the current version is missing a tag or description
  def close(description:, significance:, user_name:, start_accession: true)
    # This can be removed after migration.
    VersionMigrationService.find_and_migrate(druid)

    ObjectVersion.update_current_version(druid, description: description, significance: significance) if description || significance

    raise Dor::Exception, "Trying to close version #{cocina_object.version} on #{druid} which is not opened for versioning" unless open_for_versioning?
    raise Dor::Exception, "Trying to close version #{cocina_object.version} on #{druid} which has active assemblyWF" if active_assembly_wf?
    raise Dor::Exception, "accessionWF already created for versioned object #{druid}" if accessioning?

    workflow_client.close_version(druid: druid,
                                  version: cocina_object.version.to_s,
                                  create_accession_wf: start_accession)

    event_factory.create(druid: druid, event_type: 'version_close', data: { who: user_name, version: cocina_object.version.to_s })
  end

  # Performs checks on whether a new version can be opened for an object
  # @return [Void]
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  # @raise [Dor::Exception] if the object hasn't been accessioned,
  #    if a version is already opened
  def ensure_openable!(assume_accessioned:)
    # Raised when the object has never been accessioned.
    # The accessioned milestone is the last step of the accessionWF.
    # During local development, we need a way to open a new version even if the object has not been accessioned.
    raise(Dor::Exception, 'Object net yet accessioned') unless
        assume_accessioned || workflow_client.lifecycle(druid: druid, milestone_name: 'accessioned')
    # Raised when the current version has any incomplete wf steps and there is a versionWF.
    # The open milestone is part of the versioningWF.
    raise Dor::VersionAlreadyOpenError, 'Object already opened for versioning' if open_for_versioning?
    # Raised when the current version has any incomplete wf steps and there is an accessionWF.
    # The submitted milestone is part of the accessionWF.
    raise Dor::Exception, 'Object currently being accessioned' if accessioning?
  end

  # Performs checks on whether a new version can be opened for an object
  # @return [Integer] the version from Preservation (SDR) if a version can be opened
  # @raise [Dor::Exception] if Preservation returns 404 when queried.
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def retrieve_version_from_preservation
    Preservation::Client.objects.current_version(druid)
  rescue Preservation::Client::NotFoundError
    raise Dor::Exception, 'Preservation (SDR) is not yet answering queries about this object. ' \
                          "When an object has just been transferred, Preservation isn't immediately ready to answer queries."
  end

  # Checks if current version has any incomplete wf steps and there is a versionWF
  # @return [Boolean] true if object is open for versioning
  def open_for_versioning?
    return true if workflow_client.active_lifecycle(druid: druid, milestone_name: 'opened', version: cocina_object.version.to_s)

    false
  end

  # Checks if the current version has any incomplete wf steps and there is an accessionWF.
  # @return [Boolean] true if object is currently being accessioned
  def accessioning?
    return true if workflow_client.active_lifecycle(druid: druid, milestone_name: 'submitted', version: cocina_object.version.to_s)

    false
  end

  attr_reader :cocina_object, :event_factory

  private

  def active_assembly_wf?
    return true if workflow_client.workflow_status(druid: druid, version: cocina_object.version.to_s, workflow: 'assemblyWF', process: 'accessioning-initiate') == 'waiting'
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end

  def druid
    cocina_object.externalIdentifier
  end
end
