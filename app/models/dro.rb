# frozen_string_literal: true

# Model for a Digital Repository Object.
class Dro < ApplicationRecord
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
