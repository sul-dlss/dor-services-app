# frozen_string_literal: true

# Model for a Digital Repository Object.
class Dro < ApplicationRecord
  # @return [Cocina::Models::DRO] Cocina Digital Repository Object
  def to_cocina
    Cocina::Models::DRO.new({
      cocinaVersion: cocina_version,
      type: content_type,
      externalIdentifier: external_identifier,
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

  # @param [Cocina::Models::DRO] Cocina Digital Repository Object
  # @return [Dro] ActiveRecord Digital Repository Object
  def self.from_cocina(cocina_dro)
    new(to_model_hash(cocina_dro))
  end

  # @param [Cocina::Models::DRO] Cocina Digital Repository Object
  # @return [Hash] Hash representation of ActiveRecord DRO
  def self.to_model_hash(cocina_dro)
    dro_hash = cocina_dro.to_h
    dro_hash[:external_identifier] = dro_hash.delete(:externalIdentifier)
    dro_hash[:cocina_version] = dro_hash.delete(:cocinaVersion)
    dro_hash[:content_type]  = dro_hash.delete(:type)
    dro_hash[:description] ||= nil
    dro_hash[:identification] ||= nil
    dro_hash[:structural] ||= nil
    dro_hash[:geographic] ||= nil
    dro_hash
  end

  # @param [Cocina::Models::DRO] Cocina Digital Repository Object
  def self.upsert_cocina(cocina_dro)
    # Upsert will have to wait until we upgrade to Rails 6.
    # Dro.upsert(to_model_hash(cocina_dro), unique_by: :druid)
    dro = Dro.find_or_initialize_by(external_identifier: cocina_dro.externalIdentifier)
    dro.update(to_model_hash(cocina_dro).except(:external_identifier))
    dro.save!
  end
end
