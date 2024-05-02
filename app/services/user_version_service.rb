# frozen_string_literal: true

# Open and close versions
class UserVersionService
  class UserVersioningError < StandardError; end

  # @param [RepositoryObjectVersion] repository_object_version of the item being acted upon
  def self.create(druid:, version:)
    new(druid:, version:).create
  end

  # @param [UserVersion] user_version to withdraw
  def self.withdraw(user_version:)
    user_version.withdrawn = true
    user_version.save!
    druid = user_version.repository_object_version.repository_object.external_identifier
    EventFactory.create(druid:, event_type: 'user_version_withdrawn', data: { version: user_version.version.to_s })
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  # @param [UserVersion] user_version to move
  def self.move(druid:, version:, user_version:)
    new(druid:, version:).move(user_version)
  end

  # @param [String] druid of the item
  # @param [UserVersion] user_version to check
  def self.exist?(druid:, user_version:)
    new(druid:, version: nil).exist?(user_version:)
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  def initialize(druid:, version:)
    @druid = druid
    @repository_object = RepositoryObject.find_by!(external_identifier: druid)
    @repository_object_version = version.nil? ? @repository_object.head_version : @repository_object.versions.find_by!(version:)
  rescue ActiveRecord::RecordNotFound
    raise(UserVersioningError, "RepositoryObject not found for #{druid}")
  end

  # @return [UserVersion version] The version number of the new user version object
  # @raise [VersionService::VersioningError] if the object hasn't been accessioned, or if a version is already opened
  def create
    raise(UserVersioningError, 'RepositoryObjectVersion not closed') unless repository_object_version.closed?

    # Get the next increment of the user version (or 1 if this is the first user version)
    version = repository_object_version.user_versions.maximum(:version)&.next || 1
    UserVersion.create!(version:, repository_object_version:)
    EventFactory.create(druid:, event_type: 'user_version_created', data: { version: version.to_s })
    version
  end

  # @param [UserVersion] user_version to move
  # @raise [VersionService::VersioningError] if the object hasn't been accessioned
  def move(user_version)
    raise(UserVersioningError, 'RepositoryObject not closed') unless repository_object_version.closed?

    user_version.repository_object_version = repository_object_version
    user_version.save!
    EventFactory.create(druid:, event_type: 'user_version_moved', data: { version: user_version.version.to_s })
  end

  # @param [UserVersion] user_version to check
  # @return [Boolean] true if the user version exists
  def exist?(user_version:)
    repository_object.versions.map { |version| version.user_versions.include? user_version }.any?
  end

  attr_reader :druid, :repository_object, :repository_object_version
end
