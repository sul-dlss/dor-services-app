# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the AdminPolicyAdministrative schema to the
    # Fedora 3 data model rights
    class AdministrativeMetadata
      def self.write(administrative_metadata, administrative)
        ng_xml = administrative_metadata.ng_xml
        admin_node = ng_xml.xpath('//administrativeMetadata').first
        # Clear out the nodes we are updating
        admin_node.xpath('registration/workflow|registration/collection|dissemination/workflow').each(&:remove)

        # TODO: need to see if this node already exists
        admin_node.add_child "<dissemination><workflow id=\"#{administrative.disseminationWorkflow}\" /></dissemination>"

        registration_workflows = Array(administrative.registrationWorkflow).map { |wf_id| "<workflow id=\"#{wf_id}\" />" }.join
        registration_collections = Array(administrative.collectionsForRegistration).map { |wf_id| "<collection id=\"#{wf_id}\" />" }.join
        admin_node.add_child "<registration>#{registration_workflows}#{registration_collections}</registration>"

        administrative_metadata.ng_xml_will_change!
      end
    end
  end
end
