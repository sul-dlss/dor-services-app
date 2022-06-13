# frozen_string_literal: true

# Creates the Ur-AdminPolicy which is the apo that governs itself and all of the other AdminPolicies in the system
class UrAdminPolicyFactory
  # If an object references the Ur-AdminPolicy, it has to exist first.
  # This is particularly important in testing, where the repository may be empty.
  def self.create
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

    cocina_object_with_metadata = CocinaObjectStore.store(admin_policy_cocina, skip_lock: true)
    Notifications::ObjectCreated.publish(model: cocina_object_with_metadata)
  end
end
