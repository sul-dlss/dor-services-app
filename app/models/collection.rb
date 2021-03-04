# frozen_string_literal: true

# Model for a Collection.
class Collection < ApplicationRecord
  def to_cocina
    Cocina::Models::Collection.new({
      type: content_type,
      externalIdentifier: druid,
      label: label,
      version: version,
      access: access,
      administrative: administrative,
      description: description,
      identification: identification
    }.compact)
  end

  def self.from_cocina(collection)
    new(to_model_hash(collection))
  end

  def self.to_model_hash(collection_dro)
    collection_hash = collection_dro.to_h
    collection_hash[:druid] = collection_hash.delete(:externalIdentifier)
    collection_hash[:content_type] = collection_hash.delete(:type)
    collection_hash[:administrative] ||= nil
    collection_hash[:description] ||= nil
    collection_hash[:identification] ||= nil
    collection_hash
  end

  def self.upsert_cocina(collection_dro)
    # Upsert will have to wait until we upgrade to Rails 6.
    # Collection.upsert(to_model_hash(collection_dro), unique_by: :druid)
    collection = Collection.find_or_initialize_by(druid: collection_dro.externalIdentifier)
    collection.update(to_model_hash(collection_dro).except(:druid))
    collection.save!
  end
end
