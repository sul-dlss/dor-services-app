# frozen_string_literal: true

# Creates the Ur-AdminPolicy which is the apo that governs itself and all of the other AdminPolicies in the system
class UrAdminPolicyFactory
  # If an object references the Ur-AdminPolicy, it has to exist first.
  # This is particularly important in testing, where the repository may be empty.
  def self.create # rubocop:disable Metrics/AbcSize
    admin_policy_cocina = Cocina::Models::AdminPolicy.new(
      type: Cocina::Models::ObjectType.admin_policy,
      externalIdentifier: Settings.ur_admin_policy.druid,
      label: Settings.ur_admin_policy.label,
      version: 1,
      administrative: {
        hasAdminPolicy: Settings.ur_admin_policy.druid,
        hasAgreement: Settings.ur_admin_policy.agreement,
        accessTemplate: {
          view: 'dark',
          download: 'none'
        }
      },
      description: {
        title: [{ value: 'Test Admin Policy' }],
        purl: Purl.for(druid: Settings.ur_admin_policy.druid)
      }
    )

    repository_object = RepositoryObject.create_from(cocina_object: admin_policy_cocina)
    Indexer.reindex(cocina_object: repository_object.head_version.to_cocina_with_metadata)
  end
end
