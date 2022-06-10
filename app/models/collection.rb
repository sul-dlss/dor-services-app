# frozen_string_literal: true

# Model for a Collection.
class Collection < RepositoryRecord
  # @return [Cocina::Models::Collection] Cocina collection
  def to_cocina
    Cocina::Models::Collection.new(to_h)
  end

  # @return [Hash] collection instance as a hash
  def to_h
    {
      cocinaVersion: cocina_version,
      type: collection_type,
      externalIdentifier: external_identifier,
      label:,
      version:,
      access:,
      administrative:,
      description:,
      identification:
    }.compact
  end

  # @param [Cocina::Models::Collection] Cocina collection
  # @return [Collection] ActiveRecord collection
  def self.from_cocina(cocina_collection)
    new(to_model_hash(cocina_collection))
  end

  # @param [Cocina::Models::Collection] Cocina collection
  # @return [Hash] Hash representation of ActiveRecord collection
  def self.to_model_hash(cocina_collection)
    collection_hash = cocina_collection.to_h
    collection_hash[:external_identifier] = collection_hash.delete(:externalIdentifier)
    collection_hash[:cocina_version] = collection_hash.delete(:cocinaVersion)
    collection_hash[:collection_type] = collection_hash.delete(:type)
    collection_hash
  end

  # @param [Cocina::Models::Collection] Cocina collection
  def self.upsert_cocina(cocina_collection)
    # Upsert will have to wait until we upgrade to Rails 6.
    # Collection.upsert(to_model_hash(collection_dro), unique_by: :druid)
    collection = Collection.find_or_initialize_by(external_identifier: cocina_collection.externalIdentifier)
    collection.update(to_model_hash(cocina_collection).except(:external_identifier))
    collection.save!
    collection
  end
end
