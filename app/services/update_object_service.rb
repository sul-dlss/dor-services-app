# frozen_string_literal: true

# This handles all of the business logic around updating an object.
# This includes:
#   sending a rabbitMQ notification
#   logging an event
class UpdateObjectService
  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that is provided.
  # @param [Cocina::Models::DRO|Collection|AdminPolicy|DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina_object
  # @param [#create] event_factory creates events
  # @param [boolean] skip_lock do not perform an optimistic lock check
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore.
  # @raise [StateLockError] raised if optimistic lock failed.
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def self.update(cocina_object, event_factory: EventFactory, skip_lock: false)
    new(event_factory:).update(cocina_object, skip_lock:)
  end

  def initialize(event_factory: EventFactory)
    @event_factory = event_factory
  end

  def update(cocina_object, skip_lock: false)
    Cocina::ObjectValidator.validate(cocina_object)
    # Only update if already exists in PG (i.e., added by create or migration).
    cocina_object_with_metadata = CocinaObjectStore.store(cocina_object, skip_lock:)

    cocina_object_without_metadata = Cocina::Models.without_metadata(cocina_object)

    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update', data: { success: true, request: cocina_object_without_metadata.to_h })

    # Broadcast this update action to a topic
    Notifications::ObjectUpdated.publish(model: cocina_object_with_metadata)
    cocina_object_with_metadata
  rescue Cocina::ValidationError => e
    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update',
                         data: { success: false, error: e.message, request: Cocina::Models.without_metadata(cocina_object).to_h })
    raise
  end

  private

  attr_reader :event_factory
end
