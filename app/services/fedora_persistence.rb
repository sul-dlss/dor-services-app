# frozen_string_literal: true

# Persistence methods that are tightly coupled to Fedora 3
module FedoraPersistence
  extend ActiveSupport::Concern

  # This is only public for migration use.
  def fedora_find(druid)
    item = Dor.find(druid)
    models = ActiveFedora::ContentModel.models_asserted_by(item)
    item = item.adapt_to(Etd) if models.include?('info:fedora/afmodel:Etd')
    item
  rescue ActiveFedora::ObjectNotFoundError
    raise CocinaObjectStore::CocinaObjectNotFoundError
  rescue Rubydora::FedoraInvalidRequest, StandardError => e
    new_message = "Unable to find Fedora object or map to cmodel - is identityMetadata DS empty? #{e.message}"
    raise e.class, new_message, e.backtrace
  end

  private

  # In later steps in the migration, the *fedora* methods will be replaced by the *ar* methods.

  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata, Cocina::Models::AdminPolicyWithMetadata] cocina_object
  def fedora_to_cocina_find(druid)
    fedora_object = fedora_find(druid)
    cocina_object = Cocina::Mapper.build(fedora_object)
    Cocina::Models.with_metadata(cocina_object, fedora_lock_for(fedora_object), created: fedora_object.create_date.to_datetime, modified: fedora_object.modified_date.to_datetime)
  end

  def fedora_lock_for(fedora_object)
    # This should be opaque, but this makes troubeshooting easier.
    [fedora_object.pid, fedora_object.modified_date.to_datetime.iso8601].join('=')
  end

  # @return [Array] array consisting of created date and modified date
  def cocina_to_fedora_save(cocina_object, skip_lock: false)
    # Currently this only supports an update, not a save.
    fedora_object = fedora_find(cocina_object.externalIdentifier)

    fedora_check_lock(fedora_object, cocina_object) unless skip_lock

    # Updating produces a different Cocina object than it was provided.
    Cocina::ObjectUpdater.run(fedora_object, Cocina::Models.without_metadata(cocina_object))
    [fedora_object.create_date.to_datetime, fedora_object.modified_date.to_datetime, fedora_lock_for(fedora_object)]
  rescue Cocina::Mapper::MapperError => e
    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update',
                         data: { success: false, error: e.message, request: Cocina::Models.without_metadata(cocina_object).to_h })
    raise
  end

  def fedora_check_lock(fedora_object, cocina_object)
    return if cocina_object.respond_to?(:lock) && fedora_lock_for(fedora_object) == cocina_object.lock

    raise CocinaObjectStore::StaleLockError, "Expected lock of #{fedora_lock_for(fedora_object)} but received #{cocina_object.lock}."
  end

  def fedora_exists?(druid)
    fedora_find(druid)
    true
  rescue CocinaObjectStore::CocinaObjectNotFoundError
    false
  end

  def fedora_destroy(druid)
    fedora_find(druid).destroy
  end

  # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @param [String] druid
  # @return [Array] array consisting of created date, modified date, and lock
  # @raises SymphonyReader::ResponseError if symphony connection failed
  def fedora_create(cocina_object, druid:)
    fedora_object = Cocina::ObjectCreator.create(cocina_object, druid: druid)
    [fedora_object.create_date.to_datetime, fedora_object.modified_date.to_datetime, fedora_lock_for(fedora_object)]
  end
end
