# frozen_string_literal: true

# Open and close versions
class VersionService
  class VersioningError < StandardError; end

  class CocinaObjectNotFoundError < VersioningError; end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  # @raise [CocinaObjectNotFoundError] if the object is not found
  # @raise [VersioningError] if the version does not match the head version
  def self.open?(...)
    new(...).open?
  end

  # @param [Cocina::Models::DRO,Cocina::Models::Collection] cocina_object the item being acted upon
  # @param [String] description set description of version change
  # @param [String] opening_user_name add opening username to the events datastream
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  def self.open(cocina_object:, description:, opening_user_name: nil, assume_accessioned: false)
    new(druid: cocina_object.externalIdentifier, version: cocina_object.version)
      .open(description:,
            opening_user_name:,
            assume_accessioned:,
            cocina_object:)
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  def self.can_open?(druid:, version:, assume_accessioned: false)
    new(druid:, version:).can_open?(assume_accessioned:)
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  # @param [String] description describes the version change
  # @param [String] user_name add username to the events datastream
  # @param [Boolean] start_accession (true) set to true if you want accessioning to start, false otherwise
  # @param [String] user_versions (none) one of none, new, update
  def self.close(druid:, version:, description: nil, user_name: nil, start_accession: true, user_versions: 'none')
    new(druid:, version:).close(description:,
                                user_name:,
                                start_accession:,
                                user_versions:)
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  def self.can_close?(druid:, version:)
    new(druid:, version:).can_close?
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  def initialize(druid:, version:)
    @druid = druid
    @version = version
  end

  # Increments the version number and initializes versioningWF for the object
  # @param [Cocina::Models::DRO,Cocina::Models::Collection] cocina_object the item being acted upon
  # @param [String] description set description of version change (required)
  # @param [String] opening_user_name add opening username to the events datastream (optional)
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  # @return [Cocina::Models::DRO, Cocina::Models::AdminPolicy, Cocina::Models::Collection] updated cocina object
  # @raise [VersionService::VersioningError] if the object hasn't been accessioned, or if a version is already opened
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def open(cocina_object:, description:, assume_accessioned:, opening_user_name: nil)
    raise ArgumentError, 'description is required to open a new version' if description.blank?

    ensure_openable!(assume_accessioned:)
    if Settings.version_service.sync_with_preservation
      sdr_version = retrieve_version_from_preservation
      new_object_version = ObjectVersion.sync_then_increment_version(druid:, known_version: sdr_version, description:)
    else
      # This is for testing when we don't have the SDR container available
      new_object_version = ObjectVersion.increment_version(druid:, description:)
    end

    update_cocina_object = cocina_object
    RepositoryObject.find_by!(external_identifier: druid).open_version!(description:)
    # TODO: when we stop calling the UpdateObjectService, after we've migrated to RepostoryObjects, we may need to trigger indexing:
    #       e.g.: Notifications::ObjectUpdated.publish(model: cocina_object_with_metadata)

    # Skipping open check since not yet opened.
    update_cocina_object = UpdateObjectService.update(cocina_object.new(version: new_object_version.version), skip_open_check: true) if cocina_object.version != new_object_version.version

    workflow_client.create_workflow_by_name(druid, 'versioningWF', version: new_object_version.version.to_s)

    EventFactory.create(druid:, event_type: 'version_open', data: { who: opening_user_name, version: new_object_version.version.to_s })
    update_cocina_object
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  # @raise [CocinaObjectNotFoundError] if the object is not found
  # @raise [VersioningError] if the version does not match the head version
  def open?
    repo_obj = RepositoryObject.find_by(external_identifier: druid)

    raise CocinaObjectNotFoundError, "Couldn't find object with 'external_identifier'=#{druid}" unless repo_obj

    raise VersioningError, "Version #{version} does not match head version #{repo_obj.head_version.version}" if version != repo_obj.head_version.version

    repo_obj.open?
  end

  # Determines whether a new version can be opened for an object.
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  # @return [Boolean] true if a new version can be opened.
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def can_open?(assume_accessioned: false)
    ensure_openable!(assume_accessioned:)
    retrieve_version_from_preservation if Settings.version_service.sync_with_preservation
    true
  rescue VersionService::VersioningError
    false
  end

  # Sets versioningWF:submit-version to completed and initiates accessionWF for the object
  # @param [String] :description describes the version change
  # @param [String] :user_name add username to the events datastream
  # @param [Boolean] :start_accession set to true if you want accessioning to start (default), false otherwise
  # @param [String] :user_versions create, update, or do nothing with user_versions on close
  # @raise [VersionService::VersioningError] if the object hasn't been opened for versioning, or if accessionWF has
  #   already been instantiated or the current version is missing a description
  # @raise [ArgumentError] if user_versions is not one of none, new, update
  def close(description:, user_name:, start_accession: true, user_versions: 'none')
    user_version_options = %w[none new update]

    raise ArgumentError, "user_version must be one of #{user_version_options.join(', ')}" unless user_version_options.include?(user_versions)

    ObjectVersion.update_current_version(druid:, description:) if description

    ensure_closeable!

    repository_object = RepositoryObject.find_by!(external_identifier: druid)

    # Default to creating accessionWF when calling close_version
    workflow_client.close_version(druid:,
                                  version: version.to_s,
                                  create_accession_wf: start_accession)

    repository_object.close_version!(description:)

    EventFactory.create(druid:, event_type: 'version_close', data: { who: user_name, version: version.to_s })

    update_user_version(user_versions:, repository_object:)
  end

  # Determines whether a version can be closed for an object.
  # @return [Boolean] true if the version can be closed.
  def can_close?
    ensure_closeable!
    true
  rescue VersionService::VersioningError
    false
  end

  # Performs checks on whether a new version can be opened for an object
  # @return [Void]
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  # @raise [VersionService::VersioningError] if the object hasn't been accessioned,
  #    if a version is already opened
  def ensure_openable!(assume_accessioned:)
    # Raised when the object has never been accessioned.
    # The accessioned milestone is the last step of the accessionWF.
    # During local development, we need a way to open a new version even if the object has not been accessioned.
    raise(VersionService::VersioningError, 'Object net yet accessioned') unless
        assume_accessioned || workflow_state_service.accessioned?
    # Raised when the current version has any incomplete wf steps and there is a versionWF.
    # The open milestone is part of the versioningWF.
    raise VersionService::VersioningError, 'Object already opened for versioning' if open?
    # Raised when the current version has any incomplete wf steps and there is an accessionWF.
    # The submitted milestone is part of the accessionWF.
    raise VersionService::VersioningError, 'Object currently being accessioned' if accessioning?
  end

  # Performs checks on whether a new version can be opened for an object
  # @return [Integer] the version from Preservation (SDR) if a version can be opened
  # @raise [VersionService::VersioningError] if Preservation returns 404 when queried.
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def retrieve_version_from_preservation
    Preservation::Client.objects.current_version(druid)
  rescue Preservation::Client::NotFoundError
    raise VersionService::VersioningError, 'Preservation (SDR) is not yet answering queries about this object. ' \
                                           "When an object has just been transferred, Preservation isn't immediately ready to answer queries."
  end

  attr_reader :druid, :version

  private

  delegate :assembling?, :accessioning?, to: :workflow_state_service

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end

  def workflow_state_service
    @workflow_state_service ||= WorkflowStateService.new(druid:, version:)
  end

  def ensure_closeable!
    raise VersionService::VersioningError, "Trying to close version #{version} on #{druid} which is not opened for versioning" unless open?
    raise VersionService::VersioningError, "Trying to close version #{version} on #{druid} which has active assemblyWF" if assembling?
    raise VersionService::VersioningError, "accessionWF already created for versioned object #{druid}" if accessioning?
  end

  def update_user_version(user_versions:, repository_object:)
    return if user_versions == 'none'
    return UserVersionService.create(druid:, version: repository_object.last_closed_version.version) if user_versions == 'new'

    # If called with 'update', but there are no user versions to update, create a new user version.
    return UserVersionService.create(druid:, version: repository_object.last_closed_version.version) if repository_object.user_versions.empty?

    max_user_version = repository_object.user_versions.maximum(:version)
    UserVersionService.move(druid:, version: repository_object.last_closed_version.version, user_version: max_user_version)
  end
end
