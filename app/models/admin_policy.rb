# frozen_string_literal: true

# Model for an AdminPolicy.
class AdminPolicy < ApplicationRecord
  def to_cocina
    Cocina::Models::AdminPolicy.new({
      type: 'http://cocina.sul.stanford.edu/models/admin_policy.jsonld',
      externalIdentifier: druid,
      label: label,
      version: version,
      administrative: administrative,
      description: description
    }.compact)
  end

  def self.from_cocina(admin_policy)
    new(to_model_hash(admin_policy))
  end

  def self.to_model_hash(cocina_admin_policy)
    admin_policy_hash = cocina_admin_policy.to_h
    admin_policy_hash[:druid] = admin_policy_hash.delete(:externalIdentifier)
    admin_policy_hash.delete(:type)
    admin_policy_hash[:description] ||= nil
    admin_policy_hash
  end

  def self.upsert_cocina(cocina_admin_policy)
    # Upsert will have to wait until we upgrade to Rails 6.
    # Dro.upsert(to_model_hash(cocina_admin_policy), unique_by: :druid)
    admin_policy = AdminPolicy.find_or_initialize_by(druid: cocina_admin_policy.externalIdentifier)
    admin_policy.update(to_model_hash(cocina_admin_policy).except(:druid))
    admin_policy.save!
  end
end
