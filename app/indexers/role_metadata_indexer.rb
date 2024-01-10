# frozen_string_literal: true

class RoleMetadataIndexer
  attr_reader :cocina

  def initialize(cocina:, **)
    @cocina = cocina
  end

  # @return [Hash] the partial solr document for roleMetadata
  def to_solr
    Array(cocina.administrative.roles).each_with_object({}) do |role, solr_doc|
      solr_doc['apo_register_permissions_ssim'] = serialize(role.members) if role.name == 'dor-apo-manager'
      solr_doc["apo_role_#{role.name}_ssim"] = serialize(role.members.select { |member| member.type == 'workgroup' })
      solr_doc["apo_role_person_#{role.name}_ssim"] = serialize(role.members.select { |member| member.type == 'sunetid' })
    end
  end

  private

  def serialize(members)
    members.map { |member| [member.type, member.identifier].join(':') }
  end
end
