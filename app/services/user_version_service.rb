# frozen_string_literal: true

# Create, withdraw, and move UserVersions
class UserVersionService
  class UserVersioningError < StandardError; end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  # @return [Integer] The version number of the new user version object
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not found for the version
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not closed
  def self.create(druid:, version:)
    repository_object_version = repository_object_version(druid:, version:)
    raise(UserVersioningError, 'RepositoryObjectVersion not closed') unless repository_object_version.closed?

    # Get the next increment of the user version (or 1 if this is the first user version)
    next_user_version = repository_object_version.repository_object.user_versions.maximum(:version)&.next || 1
    UserVersion.create!(version: next_user_version, repository_object_version:)
    EventFactory.create(druid:, event_type: 'user_version_created', data: { version: version.to_s })
    next_user_version
  end

  # @param [String] druid of the item
  # @param [integer] user_version version to withdraw
  # @param [Boolean] withdraw true to withdraw the user version, false to unwithdraw
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not found for the version
  def self.withdraw(druid:, user_version:, withdraw: true)
    user_version_for(druid:, user_version:).update(withdrawn: withdraw)
    EventFactory.create(druid:, event_type: 'user_version_withdrawn', data: { version: user_version.to_s, withdrawn: withdraw })
  end

  # @param [String] druid of the item
  # @param [Integer] RepositoryObjectVersion version of the item to move to
  # @param [integer] user_version version to move
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not found for the version
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not closed
  def self.move(druid:, version:, user_version:)
    repository_object_version = repository_object_version(druid:, version:)
    raise(UserVersioningError, 'RepositoryObjectVersion not closed') unless repository_object_version.closed?

    user_version_for(druid:, user_version:).update(repository_object_version:)
    EventFactory.create(druid:, event_type: 'user_version_moved', data: { version: user_version.to_s })
  end

  # @param [String] druid of the item
  # @param [integer] user_version version to move
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  def self.exist?(druid:, user_version:)
    user_version_for(druid:, user_version:).present?
  end

  # @param [String] druid of the item
  # @param [integer,nil] user_version of the latest UserVersion or nil if the item has no UserVersions
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  def self.latest_user_version(druid:)
    repository_object = repository_object(druid:)
    repository_object.user_versions.maximum(:version)
  end

  # @param [String] druid of the item
  # @param [integer] user_version of the UserVersion
  # @return [Integer] The object version
  def self.object_version_for(druid:, user_version:)
    user_version_for(druid:, user_version:).repository_object_version.version
  end

  # private below

  # @return [RepositoryObject] The repository object for the druid
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  def self.repository_object(druid:)
    RepositoryObject.find_by!(external_identifier: druid)
  rescue ActiveRecord::RecordNotFound
    raise(UserVersioningError, "RepositoryObject not found for #{druid}")
  end

  # @return [RepositoryObjectVersion] The repository object version for the version number or for the head version if version not provided
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not found for the version
  def self.repository_object_version(druid:, version:)
    repository_object = repository_object(druid:)
    version.nil? ? repository_object.head_version : repository_object.versions.find_by!(version:)
  rescue ActiveRecord::RecordNotFound
    raise(UserVersioningError, "RepositoryObjectVersion #{version} not found for #{druid}")
  end

  def self.user_version_for(druid:, user_version:)
    repository_object = repository_object(druid:)
    repository_object.user_versions.find_by(version: user_version)
  end

  private_class_method :repository_object, :repository_object_version, :user_version_for
end
