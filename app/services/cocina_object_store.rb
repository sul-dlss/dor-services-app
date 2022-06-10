# frozen_string_literal: true

# Abstracts persistence operations for Cocina objects.
# For the actions that are supported, this class includes step that happen regardless of the datastore.
# For example, publishing a notification upon create.
class CocinaObjectStore
  # Generic base error class.
  class CocinaObjectStoreError < StandardError; end

  # Cocina object not found in datastore.
  class CocinaObjectNotFoundError < CocinaObjectStoreError; end

  # Cocina object in datastore has been updated since this instance was retrieved.
  class StaleLockError < CocinaObjectStoreError; end

  # Retrieves a Cocina object from the datastore.
  # @param [String] druid
  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata, Cocina::Models::AdminPolicyWithMetadata] cocina_object
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.find(druid)
    new.find(druid)
  end

  # Determine if an object exists in the datastore.
  # @param [String] druid
  # @return [boolean] true if object exists
  def self.exists?(druid)
    new.exists?(druid)
  end

  # Updates a Cocina object in the datastore.
  # @param [Cocina::Models::DRO|Collection|AdminPolicy|DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina_object
  # @param [boolean] skip_lock do not perform an optimistic lock check
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore.
  # @raise [StateLockError] raised if optimistic lock failed.
  # @return [Cocina::Models::AdminPolicyWithMetadata,Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata] the saved object with its metadata
  def self.store(cocina_object, skip_lock:)
    new.store(cocina_object, skip_lock:)
  end

  # Removes a Cocina object from the datastore.
  # @param [String] druid
  # @raise [CocinaObjectNotFoundError] raised when the Cocina object is not found.
  def self.destroy(druid)
    new.destroy(druid)
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

  # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata]
  def find(druid)
    ar_to_cocina_find(druid)
  end

  def store(cocina_object, skip_lock:)
    cocina_to_ar_save(cocina_object, skip_lock:)
  end

  def exists?(druid)
    ar_exists?(druid)
  end

  # This is only public for migration use.
  def ar_exists?(druid)
    Dro.exists?(external_identifier: druid) || Collection.exists?(external_identifier: druid) || AdminPolicy.exists?(external_identifier: druid)
  end

  def destroy(druid)
    cocina_object = CocinaObjectStore.find(druid)

    ar_destroy(druid)

    Notifications::ObjectDeleted.publish(model: cocina_object, deleted_at: Time.zone.now)
  end

  private

  # The *ar* methods are private. In later steps in the migration, the *ar* methods will be invoked by the
  # above public methods.

  # Persist a Cocina object with ActiveRecord.
  # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @return [Cocina::Models::AdminPolicyWithMetadata,Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata] the saved object with its metadata
  # @raise [Cocina::ValidationError] if externalIdentifier or sourceId not unique
  def cocina_to_ar_save(cocina_object, skip_lock: false)
    ar_check_lock(cocina_object) unless skip_lock

    model_clazz = case cocina_object
                  when Cocina::Models::AdminPolicy, Cocina::Models::AdminPolicyWithMetadata
                    AdminPolicy
                  when Cocina::Models::DRO, Cocina::Models::DROWithMetadata
                    Dro
                  when Cocina::Models::Collection, Cocina::Models::CollectionWithMetadata
                    Collection
                  else
                    raise CocinaObjectStoreError, "unsupported type #{cocina_object&.type}"
                  end
    ar_cocina_object = model_clazz.upsert_cocina(Cocina::Models.without_metadata(cocina_object))
    ar_cocina_object.to_cocina_with_metadata
  rescue ActiveRecord::RecordNotUnique => e
    message = if e.message.include?('dro_source_id_idx')
                source_id = cocina_object.identification.sourceId
                druid = Dro.find_by("identification->>'sourceId' = ?", source_id).external_identifier
                "An object (#{druid}) with the source ID '#{cocina_object.identification.sourceId}' has already been registered."
              else
                'ExternalIdentifier or sourceId is not unique.'
              end
    raise Cocina::ValidationError.new(message, status: :conflict)
  end

  def ar_check_lock(cocina_object)
    ar_object = ar_find(cocina_object.externalIdentifier)
    return if cocina_object.respond_to?(:lock) && ar_object.external_lock == cocina_object.lock

    raise StaleLockError, "Expected lock of #{ar_object.external_lock} but received #{cocina_object.lock}."
  end

  # Find a Cocina object persisted by ActiveRecord.
  # @param [String] druid to find
  # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata]
  def ar_to_cocina_find(druid)
    ar_find(druid).to_cocina_with_metadata
  end

  # Find an ActiveRecord Cocina object.
  # @param [String] druid to find
  # @return [Dro, AdminPolicy, Collection]
  def ar_find(druid)
    ar_cocina_object = Dro.find_by(external_identifier: druid) ||
                       AdminPolicy.find_by(external_identifier: druid) ||
                       Collection.find_by(external_identifier: druid)

    raise CocinaObjectNotFoundError unless ar_cocina_object

    ar_cocina_object
  end

  def ar_destroy(druid)
    ar_find(druid).destroy
  end
end
