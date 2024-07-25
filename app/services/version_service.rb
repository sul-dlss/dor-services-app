# frozen_string_literal: true

# Open and close versions
# rubocop:disable Metrics/ClassLength
class VersionService
  class VersioningError < StandardError; end

  class CocinaObjectNotFoundError < VersioningError; end

  DEFAULT_USER_VERSION_MODE = :update_if_existing

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
  # @param [Symbol] :user_version_mode :create, :update, :update_if_existing (default), or :none (do nothing) with user_versions on close
  def self.close(druid:, version:, description: nil, user_name: nil, start_accession: true, user_version_mode: DEFAULT_USER_VERSION_MODE)
    new(druid:, version:).close(description:,
                                user_name:,
                                start_accession:,
                                user_version_mode:)
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
  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::AdminPolicyWithMetadata, Cocina::Models::CollectionWithMetadata] updated cocina object
  # @raise [VersionService::VersioningError] if the object hasn't been accessioned, or if a version is already opened
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def open(cocina_object:, description:, assume_accessioned:, opening_user_name: nil)
    raise ArgumentError, 'description is required to open a new version' if description.blank?

    ensure_openable!(assume_accessioned:)
    repository_object = RepositoryObject.find_by!(external_identifier: cocina_object.externalIdentifier)
    check_version!(current_version: repository_object.head_version.version)

    repository_object.open_version!(description:)

    # Reloading to get correct lock value.
    Indexer.reindex_later(cocina_object: repository_object.reload.to_cocina_with_metadata)

    new_version = repository_object.opened_version.version
    workflow_client.create_workflow_by_name(druid, 'versioningWF', version: new_version.to_s)
    EventFactory.create(druid:, event_type: 'version_open', data: { who: opening_user_name, version: new_version.to_s })
    repository_object.to_cocina_with_metadata
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
  # @param [Symbol] :user_version_mode :none (do nothing), :new, :update, or :update_if_existing (default) with user_versions on close
  # @raise [VersionService::VersioningError] if the object hasn't been opened for versioning, or if accessionWF has
  #   already been instantiated or the current version is missing a description
  # @raise [ArgumentError] if user_versions is not one of none, new, update
  def close(description:, user_name:, start_accession: true, user_version_mode: DEFAULT_USER_VERSION_MODE)
    user_version_mode_options = %i[none new update update_if_existing]

    raise ArgumentError, "user_version_mode must be one of #{user_version_mode_options.join(', ')}" unless user_version_mode_options.include?(user_version_mode)

    ensure_closeable!

    repository_object = RepositoryObject.find_by!(external_identifier: druid)

    repository_object.close_version!(description:)
    workflow_client.create_workflow_by_name(druid, 'accessionWF', version: version.to_s) if start_accession

    EventFactory.create(druid:, event_type: 'version_close', data: { who: user_name, version: version.to_s })

    update_user_version(user_version_mode:, repository_object:)
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

  def update_user_version(user_version_mode:, repository_object:)
    case user_version_mode
    when :new
      create_user_version(repository_object)
    when :update
      no_user_versions?(repository_object) ? create_user_version(repository_object) : move_user_version(repository_object)
    when :update_if_existing
      move_user_version(repository_object) unless no_user_versions?(repository_object)
    end
    # :none falls through and does nothing
  end

  def no_user_versions?(repository_object)
    repository_object.user_versions.empty?
  end

  def create_user_version(repository_object)
    UserVersionService.create(druid:, version: repository_object.last_closed_version.version)
  end

  def move_user_version(repository_object)
    UserVersionService.move(druid:, version: repository_object.last_closed_version.version, user_version: repository_object.head_user_version)
  end

  def check_version!(current_version:)
    return unless Settings.version_service.sync_with_preservation

    preservation_version = retrieve_version_from_preservation

    return if preservation_version == current_version

    raise VersionService::VersioningError, "Version from Preservation is out of sync. Preservation expects #{preservation_version} but current version is #{current_version}"
  end
end
# rubocop:enable Metrics/ClassLength
