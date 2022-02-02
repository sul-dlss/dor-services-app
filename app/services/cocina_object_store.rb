# frozen_string_literal: true

# Abstracts persistence operations for Cocina objects
class CocinaObjectStore
  # Generic base error class.
  class CocinaObjectStoreError < StandardError; end

  # Cocina object not found in datastore.
  class CocinaObjectNotFoundError < CocinaObjectStoreError; end

  # Retrieves a Cocina object from the datastore.
  # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object
  # @raise [SolrConnectionError] raised when cannot connect to Solr. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::Mapper::UnexpectedBuildError] raised when an mapping error occurs. This error will no longer be raised when Fedora is removed.
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.find(druid)
    new.find(druid)
  end

  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that is provided.
  # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object
  # @raise [Cocina::RoundtripValidationError] raised when validating roundtrip mapping fails. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore. This error will no longer be raised when support create.
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def self.save(cocina_object)
    new.save(cocina_object)
  end

  def find(druid)
    fedora_to_cocina_find(druid)
  end

  def save(cocina_object)
    updated_cocina_object = cocina_to_fedora_save(cocina_object)

    # Broadcast this update action to a topic
    Notifications::ObjectUpdated.publish(model: updated_cocina_object) if Settings.rabbitmq.enabled
    updated_cocina_object
  end

  private

  # In later steps in the migration, the *fedora* methods will be replaced by the *ar* methods.

  def fedora_to_cocina_find(druid)
    fedora_object = fedora_find(druid)
    Cocina::Mapper.build(fedora_object)
  end

  def cocina_to_fedora_save(cocina_object)
    # Currently this only supports an update, not a save.
    fedora_object = fedora_find(cocina_object.externalIdentifier)
    # Updating produces a different Cocina object than it was provided.
    Cocina::ObjectUpdater.run(fedora_object, cocina_object)
  end

  def fedora_find(druid)
    item = Dor.find(druid)
    models = ActiveFedora::ContentModel.models_asserted_by(item)
    item = item.adapt_to(Etd) if models.include?('info:fedora/afmodel:Etd')
    item
  rescue ActiveFedora::ObjectNotFoundError
    raise CocinaObjectNotFoundError
  end

  # The *ar* methods are private. In later steps in the migration, the *ar* methods will be invoked by the
  # above public methods.

  # Find a Cocina object persisted by ActiveRecord.
  # @param [String] druid to find
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
  def ar_to_cocina_find(druid)
    cocina_object = Dro.find_by(external_identifier: druid)&.to_cocina ||
                    AdminPolicy.find_by(external_identifier: druid)&.to_cocina ||
                    Collection.find_by(external_identifier: druid)&.to_cocina

    raise CocinaObjectNotFoundError unless cocina_object

    cocina_object
  end

  # Persist a Cocina object with ActiveRecord.
  # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
  def cocina_to_ar_save(cocina_object)
    model_clazz = case cocina_object
                  when Cocina::Models::AdminPolicy
                    AdminPolicy
                  when Cocina::Models::DRO
                    Dro
                  when Cocina::Models::Collection
                    Collection
                  else
                    raise CocinaObjectStoreError, "unsupported type #{cocina_object&.type}"
                  end
    model_clazz.upsert_cocina(cocina_object)
    cocina_object
  end
end
