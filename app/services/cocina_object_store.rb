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
    fedora_object = fedora_find(druid)
    Cocina::Mapper.build(fedora_object)
  end

  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that is provided.
  # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object
  # @raise [Cocina::RoundtripValidationError] raised when validating roundtrip mapping fails. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore. This error will no longer be raised when support create.
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def self.save(cocina_object)
    # Currently this only supports an update, not a save.
    fedora_object = fedora_find(cocina_object.externalIdentifier)
    # Updating produces a different Cocina object than it was provided.
    updated_cocina_object = Cocina::ObjectUpdater.run(fedora_object, cocina_object)

    # Broadcast this update action to a topic
    Notifications::ObjectUpdated.publish(model: updated_cocina_object) if Settings.rabbitmq.enabled
    updated_cocina_object
  end

  def self.fedora_find(druid)
    item = Dor.find(druid)
    models = ActiveFedora::ContentModel.models_asserted_by(item)
    item = item.adapt_to(Etd) if models.include?('info:fedora/afmodel:Etd')
    item
  rescue ActiveFedora::ObjectNotFoundError
    raise CocinaObjectNotFoundError
  end
  private_class_method :fedora_find
end
