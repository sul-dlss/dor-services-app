# frozen_string_literal: true

# Model for a Digital Repository Object.
class Dro < ApplicationRecord
  # rubocop:disable Layout/LineLength
  # Version all cocina fields.
  # trigger.after(:update) do
  #   "INSERT INTO dro_versions(dro_id, druid, content_type, label, version, access, administrative, description, identification, structural, geographic, created_at, updated_at) VALUES (OLD.id, OLD.druid, OLD.content_type, OLD.label, OLD.version, OLD.access, OLD.administrative, OLD.description, OLD.identification, OLD.structural, OLD.geographic, OLD.created_at, OLD.updated_at);"
  # end

  # Version only cocina fields that have changed.
  trigger.after(:update) do
    'INSERT INTO dro_versions(dro_id, druid, content_type, label, version, access, administrative, description, identification, structural, geographic, created_at, updated_at) VALUES (OLD.id, OLD.druid, NULLIF(OLD.content_type, NEW.content_type), NULLIF(OLD.label, NEW.label), NULLIF(OLD.version, NEW.version), NULLIF(OLD.access, NEW.access), NULLIF(OLD.administrative, NEW.administrative), NULLIF(OLD.description, NEW.description), NULLIF(OLD.identification, NEW.identification), NULLIF(OLD.structural, NEW.structural), NULLIF(OLD.geographic, NEW.geographic), OLD.created_at, OLD.updated_at);'
  end
  # rubocop:enable Layout/LineLength

  def to_cocina
    Cocina::Models::DRO.new({
      type: content_type,
      externalIdentifier: druid,
      label: label,
      version: version,
      access: access,
      administrative: administrative,
      description: description,
      identification: identification,
      structural: structural,
      geographic: geographic
    }.compact)
  end

  def self.from_cocina(dro)
    new(to_model_hash(dro))
  end

  def self.to_model_hash(cocina_dro)
    dro_hash = cocina_dro.to_h
    dro_hash[:druid] = dro_hash.delete(:externalIdentifier)
    dro_hash[:content_type]  = dro_hash.delete(:type)
    dro_hash[:description] ||= nil
    dro_hash[:identification] ||= nil
    dro_hash[:structural] ||= nil
    dro_hash[:geographic] ||= nil
    dro_hash
  end

  def self.upsert_cocina(cocina_dro)
    # Upsert will have to wait until we upgrade to Rails 6.
    # Dro.upsert(to_model_hash(cocina_dro), unique_by: :druid)
    dro = Dro.find_or_initialize_by(druid: cocina_dro.externalIdentifier)
    dro.update(to_model_hash(cocina_dro).except(:druid))
    dro.save!
  end
end
