# frozen_string_literal: true

# Create, withdraw, and move UserVersions
class UserVersionService
  class UserVersioningError < StandardError; end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  # @return [UserVersion] The new user version
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not found for the version
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not closed
  def self.create(druid:, version:)
    repository_object_version = repository_object_version(druid:, version:)
    raise(UserVersioningError, 'RepositoryObjectVersion not closed') unless repository_object_version.closed?

    # Get the next increment of the user version (or 1 if this is the first user version)
    next_user_version = repository_object_version.repository_object.user_versions.maximum(:version)&.next || 1
    user_version = UserVersion.create!(version: next_user_version, repository_object_version:)
    EventFactory.create(druid:, event_type: 'user_version_created', data: { version: version.to_s })
    user_version
  end

  # @param [String] druid of the item
  # @param [integer] user_version version to withdraw
  # @param [Boolean] withdraw true to withdraw the user version, false to unwithdraw
  # @return [UserVersion] The user version
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not found for the version
  def self.withdraw(druid:, user_version:, withdraw: true)
    user_version = user_version_for(druid:, user_version:)
    user_version.update!(state: withdraw ? 'withdrawn' : 'available')
    WithdrawRestoreJob.perform_later(user_version:)
    EventFactory.create(druid:, event_type: 'user_version_withdrawn',
                        data: { version: user_version.to_s, withdrawn: withdraw })
    user_version
  rescue ActiveRecord::RecordInvalid => e
    raise(UserVersioningError, e.message)
  end

  # @param [String] druid of the item
  # @param [Integer] RepositoryObjectVersion version of the item to move to
  # @param [Integer] user_version version to move
  # @param [Boolean] publish true to publish the user version
  # @return [UserVersion] The user version
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not found for the version
  # @raise [UserVersionService::UserVersioningError] RepositoryObjectVersion not closed
  def self.move(druid:, version:, user_version:, publish: true)
    repository_object_version = repository_object_version(druid:, version:)
    raise(UserVersioningError, 'RepositoryObjectVersion not closed') unless repository_object_version.closed?

    user_version_obj = user_version_for(druid:, user_version:)
    user_version_obj.update(repository_object_version:)
    PublishJob.perform_later(druid:, user_version:, background_job_result: BackgroundJobResult.create) if publish
    EventFactory.create(druid:, event_type: 'user_version_moved', data: { version: user_version.to_s })
    user_version_obj
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

  # Mark all UserVersions other than the latest as permanently withdrawn
  # @param [String] druid of the item
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  def self.permanently_withdraw_previous_user_versions(druid:)
    # No need to notify Purl-Fetcher; it will delete the user versions because the object is being made dark.
    repository_object = repository_object(druid:)
    latest_user_version = latest_user_version(druid:)
    RepositoryObject.transaction do
      repository_object.user_versions.each do |user_version|
        next if user_version.version == latest_user_version
        next if user_version.permanently_withdrawn?

        user_version.permanently_withdrawn!
        EventFactory.create(druid:, event_type: 'user_version_permanently_withdrawn',
                            data: { version: user_version.to_s })
      end
    end
  end

  # private below

  # @return [RepositoryObject] The repository object for the druid
  # @raise [UserVersionService::UserVersioningError] RepositoryObject not found for the druid
  def self.repository_object(druid:)
    RepositoryObject.find_by!(external_identifier: druid)
  rescue ActiveRecord::RecordNotFound
    raise(UserVersioningError, "RepositoryObject not found for #{druid}")
  end

  # @return [RepositoryObjectVersion] The repository object version for the version number or for the head version if
  # version not provided
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
