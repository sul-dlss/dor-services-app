# frozen_string_literal: true

# Open and close versions
class UserVersionService
  class VersioningError < StandardError; end

  # @param [RepositoryObjectVersion] repository_object_version of the item being acted upon
  # @param [Class] event_factory (EventFactory) the factory for creating events
  def self.create(druid:, version:, event_factory: EventFactory)
    new(druid:, version:).create(event_factory:)
  end

  def self.withdraw(user_version:, event_factory: EventFactory)
    user_version.withdrawn = true
    event_factory.create(druid:, event_type: 'user_version_withdrawn', data: { version: user_version.version.to_s })
  end

  def self.move(druid:, version:, user_version:, event_factory: EventFactory)
    new(druid:, version:).move(user_version, event_factory)
  end

  # @param [String] druid of the item
  # @param [Integer] version of the item
  def initialize(druid:, version:)
    @druid = druid
    @repository_object = RepositoryObject.find_by!(external_identifier: druid)
    @repository_object_version = @repository_object.versions.find_by!(version:)
  end

  # @param [Class] event_factory (EventFactory) the factory for creating events
  # @return [UserVersion version] The version number of the new user version object
  # @raise [VersionService::VersioningError] if the object hasn't been accessioned, or if a version is already opened
  def create(event_factory:)
    raise(VersionService::VersioningError, 'RepositoryObject not closed') unless repository_object.closed?

    # Get the next increment of the user version (or 1 if this is the first user version)
    version = repository_object_version.user_versions.maximum(:version)&.next || 1
    UserVersion.create!(version:, repository_object_version:)
    event_factory.create(druid:, event_type: 'user_version_created', data: { version: version.to_s })
    version
  end

  def move(user_version, event_factory)
    raise(VersionService::VersioningError, 'RepositoryObject not closed') unless repository_object.closed?

    user_version.repository_object_version = repository_object_version
    user_version.save!
    event_factory.create(druid:, event_type: 'user_version_moved', data: { version: user_version.version.to_s })
  end

  attr_reader :druid, :repository_object, :repository_object_version
end
