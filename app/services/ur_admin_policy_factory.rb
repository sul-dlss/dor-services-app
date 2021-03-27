# frozen_string_literal: true

# Creates the Ur-AdminPolicy which is the apo that governs itself and all of the other AdminPolicies in the system
class UrAdminPolicyFactory
  # If an object references the Ur-AdminPolicy, it has to exist first.
  # This is particularly important in testing, where the repository may be empty.
  def self.create
    Dor::AdminPolicyObject.new(pid: Settings.ur_admin_policy.druid,
                               label: Settings.ur_admin_policy.label,
                               agreement_object_id: Settings.ur_admin_policy.druid,
                               mods_title: Settings.ur_admin_policy.label).tap do |ur_apo|
      ur_apo.add_relationship(:is_governed_by, "info:fedora/#{Settings.ur_admin_policy.druid}")
      ur_apo.save!
    end

    # Solves an odd bootstrapping problem, where the dor-indexing-app can only index cocina-models,
    # but cocina-model can't be built unless the AdminPolicy is found in Solr
    ActiveFedora::SolrService.add(id: Settings.ur_admin_policy.druid,
                                  objectType_ssim: ['adminPolicy'],
                                  has_model_ssim: 'info:fedora/afmodel:Dor_AdminPolicyObject')
    ActiveFedora::SolrService.commit
  end
end
