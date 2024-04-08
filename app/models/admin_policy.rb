# frozen_string_literal: true

# Model for an AdminPolicy.
class AdminPolicy < RepositoryRecord
  validates :administrative, presence: true

  # @return [Cocina::Models::AdminPolicy] Cocina Administrative Policy
  def to_cocina
    Cocina::Models::AdminPolicy.new(to_h)
  end

  # @return [Hash] Admin policy instance as a hash
  def to_h
    {
      cocinaVersion: cocina_version,
      type: Cocina::Models::ObjectType.admin_policy,
      externalIdentifier: external_identifier,
      label:,
      version:,
      administrative:,
      description:
    }.compact
  end

  # @param [Cocina::Models::AdminPolicy] Cocina Administrative Policy
  # @return [Hash] Hash representation of ActiveRecord Administrative Policy
  def self.to_model_hash(cocina_admin_policy)
    admin_policy_hash = cocina_admin_policy.to_h
    admin_policy_hash[:external_identifier] = admin_policy_hash.delete(:externalIdentifier)
    admin_policy_hash[:cocina_version] = admin_policy_hash.delete(:cocinaVersion)
    admin_policy_hash.delete(:type)
    admin_policy_hash[:description] ||= nil
    admin_policy_hash
  end

  # @param [Cocina::Models::AdminPolicy] Cocina Administrative Policy
  def self.upsert_cocina(cocina_admin_policy)
    # Upsert will have to wait until we upgrade to Rails 6.
    # Dro.upsert(to_model_hash(cocina_admin_policy), unique_by: :druid)
    admin_policy = AdminPolicy.find_or_initialize_by(external_identifier: cocina_admin_policy.externalIdentifier)
    admin_policy.update(to_model_hash(cocina_admin_policy).except(:external_identifier))
    admin_policy.save!
    admin_policy
  end
end
