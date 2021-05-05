# frozen_string_literal: true

# Model for a Collection.
class Collection < ApplicationRecord
  # rubocop:disable Layout/LineLength
  # Version all cocina fields.
  # trigger.after(:update) do
  #   "INSERT INTO collection_versions(collection_id, druid, content_type, label, version, access, administrative, description, identification, created_at, updated_at) VALUES (OLD.id, OLD.druid, OLD.content_type, OLD.label, OLD.version, OLD.access, OLD.administrative, OLD.description, OLD.identification, OLD.created_at, OLD.updated_at);"
  # end

  # Version only changed cocina fields.
  trigger.after(:update) do
    'INSERT INTO collection_versions(collection_id, druid, content_type, label, version, access, administrative, description, identification, created_at, updated_at) VALUES (OLD.id, OLD.druid, NULLIF(OLD.content_type, NEW.content_type), NULLIF(OLD.label, NEW.label), NULLIF(OLD.version, NEW.version), NULLIF(OLD.access, NEW.access), NULLIF(OLD.administrative, NEW.administrative), NULLIF(OLD.description, NEW.description), NULLIF(OLD.identification, NEW.identification), OLD.created_at, OLD.updated_at);'
  end
  # rubocop:enable Layout/LineLength

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
