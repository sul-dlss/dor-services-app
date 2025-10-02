# frozen_string_literal: true

# Abstracts persistence operations for Cocina objects.
# For the actions that are supported, this class includes step that happen regardless of the datastore.
# For example, publishing a notification upon create.
class CocinaObjectStore
  # Generic base error class.
  class CocinaObjectStoreError < StandardError; end

  # Cocina object not found in datastore.
  class CocinaObjectNotFoundError < CocinaObjectStoreError
    attr_reader :druid

    def initialize(message = nil, druid = nil)
      @druid = druid
      super(message)
    end
  end

  # Cocina object in datastore has been updated since this instance was retrieved.
  class StaleLockError < CocinaObjectStoreError; end

  DRO = 'Dro'
  COLLECTION = 'Collection'
  ADMIN_POLICY = 'AdminPolicy'

  # Retrieves a Cocina object from the datastore.
  # @param [String] druid
  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata, Cocina::Models::AdminPolicyWithMetadata] cocina_object #rubocop:disable Layout/LineLength
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.find(druid)
    new.find(druid)
  end

  # Retrieves a list of Cocina objects from the datastore.
  # @param [Array<String>] druids
  # @return [Array<Cocina::Models::DROWithMetadata,
  #                Cocina::Models::CollectionWithMetadata,
  #                Cocina::Models::AdminPolicyWithMetadata>] cocina_objects
  def self.find_all(druids)
    RepositoryObject.includes(:head_version).where(external_identifier: druids).map do |repo_object|
      repo_object.head_version.to_cocina_with_metadata
    end
  end

  # Retrieves a Cocina object from the datastore by sourceID.
  # @param [String] source_id
  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata] cocina_object
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.find_by_source_id(source_id)
    new.find_by_source_id(source_id)
  end

  # Determine if an object exists in the datastore, returning a boolean.
  # @param [String] druid
  # @param [String,Array<String>,nil] type optional cocina type to check
  # @return [boolean] true if object exists
  def self.exists?(druid, type: nil)
    new.exists?(druid, type:)
  end

  # Checks if an object exists in the datastore, raising if it does not exist.
  # @param [String] druid
  # @return [boolean] true if object exists
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.exists!(druid)
    new.exists!(druid)
  end

  # @param [Cocina::Models::DRO] cocina_item
  # @param [Boolean] swallow_exceptions (false) should this return a list even if some members aren't found?
  def self.find_collections_for(cocina_item, swallow_exceptions: false)
    # isMemberOf may be nil, in which case we want to return an empty array
    Array(cocina_item.structural.isMemberOf).filter_map do |collection_id|
      find(collection_id)
    rescue CocinaObjectNotFoundError
      raise unless swallow_exceptions
    end
  end

  # Retrieves the version of a Cocina object from the datastore.
  # @param [String] druid
  # @return [Integer] version
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.version(druid)
    new.version(druid)
  end

  # @param [String] druid to find
  # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata] for the requested version #rubocop:disable Layout/LineLength
  def find(druid, version: :head)
    RepositoryObject.find_by!(external_identifier: druid).head_version.to_cocina_with_metadata
  rescue ActiveRecord::RecordNotFound
    return bootstrap_ur_admin_policy if bootstrap_ur_admin_policy?(druid)

    raise CocinaObjectNotFoundError.new("Couldn't find object with 'external_identifier'=#{druid}", druid)
  end

  def find_by_source_id(source_id)
    RepositoryObject.find_by!(source_id:).head_version.to_cocina_with_metadata
  rescue ActiveRecord::RecordNotFound
    raise CocinaObjectNotFoundError.new("Couldn't find object with 'source_id'=#{source_id}", source_id)
  end

  def exists?(druid, type: nil)
    RepositoryObject.exists?(external_identifier: druid)
  end

  def exists!(druid)
    return true if exists?(druid)

    raise CocinaObjectNotFoundError.new("Couldn't find object with 'external_identifier'=#{druid}", druid)
  end

  def version(druid)
    RepositoryObject.joins(:head_version).select(:version).find_by!(external_identifier: druid).version
  rescue ActiveRecord::RecordNotFound
    raise CocinaObjectNotFoundError.new("Couldn't find object with 'external_identifier'=#{druid}", druid)
  end

  private

  def bootstrap_ur_admin_policy?(druid)
    Settings.enabled_features.create_ur_admin_policy && druid == Settings.ur_admin_policy.druid
  end

  def bootstrap_ur_admin_policy
    UrAdminPolicyFactory.create

    RepositoryObject.find_by(external_identifier: Settings.ur_admin_policy.druid).head_version.to_cocina_with_metadata
  end
end
