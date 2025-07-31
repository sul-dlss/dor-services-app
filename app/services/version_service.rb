# frozen_string_literal: true

# Open and close versions
# rubocop:disable Metrics/ClassLength
class VersionService
  class VersioningError < StandardError; end

  class CocinaObjectNotFoundError < VersioningError; end

  DEFAULT_USER_VERSION_MODE = :update_if_existing

  def self.open?(...)
    new(...).open?
  end

  def self.open(cocina_object:, description:, opening_user_name: nil, assume_accessioned: false, from_version: nil)
    new(druid: cocina_object.externalIdentifier, version: cocina_object.version)
      .open(description:, opening_user_name:, assume_accessioned:, cocina_object:, from_version:)
  end

  def self.can_open?(druid:, version:, assume_accessioned: false)
    new(druid:, version:).can_open?(assume_accessioned:)
  end

  def self.close(druid:, version:, description: nil, user_name: nil, start_accession: true, # rubocop:disable Metrics/ParameterLists
                 user_version_mode: DEFAULT_USER_VERSION_MODE)
    new(druid:, version:).close(description:, user_name:, start_accession:, user_version_mode:)
  end

  def self.can_close?(...)
    new(...).can_close?
  end

  def self.can_discard?(...)
    new(...).can_discard?
  end

  def self.ensure_discardable!(...)
    new(...).ensure_discardable!
  end

  def self.discard(...)
    new(...).discard
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  # @param [Workflow::StateService] workflow_state_service
  # @param [RepositoryObject] repository_object optional object to check against, otherwise it will be fetched
  def initialize(druid:, version:, workflow_state_service: nil, repository_object: nil)
    @druid = druid
    @version = version
    @workflow_state_service = workflow_state_service
    @repository_object = repository_object
  end

  # Increments the version number and initializes versioningWF for the object
  # @param [Cocina::Models::DRO,Cocina::Models::Collection] cocina_object the item being acted upon
  # @param [String] description set description of version change (required)
  # @param [String] opening_user_name add opening username to the events datastream (optional)
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  # @param [Integer,nil] from_version existing version to base the new version on, otherwise uses last_closed_version
  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::AdminPolicyWithMetadata, Cocina::Models::CollectionWithMetadata] updated cocina object # rubocop:disable Layout/LineLength
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def open(cocina_object:, description:, assume_accessioned:, opening_user_name: nil, from_version: nil) # rubocop:disable Metrics/AbcSize
    raise ArgumentError, 'description is required to open a new version' if description.blank?

    ensure_openable!(assume_accessioned:)
    check_version!(current_version: repository_object.head_version_version) unless from_version

    from_repository_object_version = from_version ? repository_object.versions.find_by!(version: from_version) : nil

    repository_object.open_version!(description:, from_version: from_repository_object_version)

    Indexer.reindex_later(druid: cocina_object.externalIdentifier)

    new_version = repository_object.opened_version.version
    Workflow::Service.create(druid:, workflow_name: 'versioningWF', version: new_version.to_s)
    EventFactory.create(druid:, event_type: 'version_open',
                        data: { who: opening_user_name, version: new_version.to_s, description: })
    # Reloading to get correct lock value.
    repository_object.reload.to_cocina_with_metadata
  end

  # @raise [CocinaObjectNotFoundError] if the object is not found
  # @raise [VersioningError] if the version does not match the head version
  def open?
    @open ||= begin
      unless repository_object
        raise CocinaObjectNotFoundError, "Couldn't find object with 'external_identifier'=#{druid}"
      end

      if version != repository_object.head_version_version
        raise VersioningError,
              "Version #{version} does not match head version #{repository_object.head_version_version}"
      end

      repository_object.open?
    end
  end

  # Determines whether a new version can be opened for an object.
  # @param [Boolean] assume_accessioned If true, does not check whether object has been accessioned.
  # @param [Boolean] check_preservation If true, checks Preservation for the current version.
  # @return [Boolean] true if a new version can be opened.
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def can_open?(assume_accessioned: false, check_preservation: true)
    @can_open ||= begin
      ensure_openable!(assume_accessioned:)
      retrieve_version_from_preservation if check_preservation && Settings.version_service.sync_with_preservation
      true
    rescue VersionService::VersioningError
      false
    end
  end

  # Sets versioningWF:submit-version to completed and initiates accessionWF for the object
  # @param [String] :description describes the version change
  # @param [String] :user_name add username to the events datastream
  # @param [Boolean] :start_accession set to true if you want accessioning to start (default), false otherwise
  # @param [Symbol] :user_version_mode :none (do nothing), :new, :update, or :update_if_existing (default) with
  # user_versions on close
  # @raise [VersionService::VersioningError] if the object hasn't been opened for versioning, or if accessionWF has
  #   already been instantiated or the current version is missing a description
  # @raise [ArgumentError] if user_versions is not one of none, new, update
  def close(description:, user_name:, start_accession: true, user_version_mode: DEFAULT_USER_VERSION_MODE) # rubocop:disable Metrics/AbcSize
    user_version_mode_options = %i[none new update update_if_existing]

    unless user_version_mode_options.include?(user_version_mode)
      raise ArgumentError,
            "user_version_mode must be one of #{user_version_mode_options.join(', ')}"
    end

    ensure_closeable!

    repository_object.close_version!(description:)
    Workflow::Service.create(druid:, workflow_name: 'accessionWF', version: version.to_s) if start_accession

    EventFactory.create(druid:, event_type: 'version_close',
                        data: { who: user_name, version: version.to_s,
                                description: repository_object.last_closed_version.version_description })

    # Accessioning will perform the publishing, so don't publish here
    update_user_version(user_version_mode:, repository_object:, publish: !start_accession)
    update_previous_user_versions(repository_object:)
  end

  # Determines whether a version can be closed for an object.
  # @return [Boolean] true if the version can be closed.
  def can_close?
    @can_close ||= begin
      ensure_closeable!
      true
    rescue VersionService::VersioningError
      false
    end
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
        assume_accessioned || accessioned?
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
    raise VersionService::VersioningError, 'Preservation (SDR) is not yet answering queries about this object. When ' \
                                           'an object has just been transferred, Preservation isn\'t immediately ' \
                                           'ready to answer queries.'
  end

  # Discards (delete) the current version of an object
  # @raise [VersionService::VersioningError] if the version cannot be discarded
  def discard
    ensure_discardable!
    repository_object.discard_open_version!
    EventFactory.create(druid: druid, event_type: 'version_discard', data: { version: version })
  end

  # Performs checks on whether a version can be discarded (deleted)
  # @return [Boolean] true if the version can be discarded.
  def can_discard?
    ensure_discardable!
    true
  rescue VersionService::VersioningError
    false
  end

  # Performs checks on whether a version can be discarded (deleted)
  # @return [Void]
  # @raise [VersionService::VersioningError] if the version cannot be discarded
  def ensure_discardable!
    unless repository_object.head_version_version == version
      raise VersionService::VersioningError,
            'Only the head version can be discarded'
    end

    repository_object.check_discard_open_version!
  rescue RepositoryObject::VersionNotDiscardable => e
    raise VersionService::VersioningError, e.message
  end

  attr_reader :druid, :version

  private

  delegate :assembling?, :accessioning?, :accessioned?, to: :workflow_state_service

  def workflow_state_service
    @workflow_state_service ||= Workflow::StateService.new(druid:, version:)
  end

  def ensure_closeable!
    unless open?
      raise VersionService::VersioningError,
            "Trying to close version #{version} on #{druid} which is not opened for versioning"
    end
    if assembling?
      raise VersionService::VersioningError,
            "Trying to close version #{version} on #{druid} which has active assemblyWF"
    end
    raise VersionService::VersioningError, "accessionWF already created for versioned object #{druid}" if accessioning?
  end

  def update_user_version(user_version_mode:, repository_object:, publish:)
    case user_version_mode
    when :new
      create_user_version(repository_object)
    when :update
      if no_user_versions?(repository_object)
        create_user_version(repository_object)
      else
        move_user_version(repository_object, publish)
      end
    when :update_if_existing
      move_user_version(repository_object, publish) unless no_user_versions?(repository_object)
    end
    # :none falls through and does nothing
  end

  def no_user_versions?(repository_object)
    repository_object.user_versions.empty?
  end

  def create_user_version(repository_object)
    UserVersionService.create(druid:, version: repository_object.last_closed_version.version)
  end

  def move_user_version(repository_object, publish)
    UserVersionService.move(druid:, version: repository_object.last_closed_version.version,
                            user_version: repository_object.head_user_version, publish:)
  end

  def check_version!(current_version:)
    return unless Settings.version_service.sync_with_preservation

    preservation_version = retrieve_version_from_preservation

    return if preservation_version == current_version

    raise VersionService::VersioningError,
          "Version from Preservation is out of sync. Preservation expects #{preservation_version} but current " \
          "version is #{current_version}"
  end

  def update_previous_user_versions(repository_object:)
    return unless repository_object.user_versions.length > 1

    cocina_object = repository_object.to_cocina
    return unless cocina_object.access.view == 'dark'

    UserVersionService.permanently_withdraw_previous_user_versions(druid:)
  end

  def repository_object
    @repository_object ||= RepositoryObject.includes(:head_version).find_by(external_identifier: druid)
  end
end
# rubocop:enable Metrics/ClassLength
