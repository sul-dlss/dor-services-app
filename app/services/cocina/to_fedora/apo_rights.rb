# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the AdminPolicyAdministrative schema to the
    # Fedora 3 data model rights
    class ApoRights
      def self.write(administrative_metadata, administrative)
        admin_node = administrative_metadata.ng_xml.xpath('//administrativeMetadata').first
        # TODO: need to see if this node already exists
        admin_node.add_child "<dissemination><workflow id=\"#{administrative.disseminationWorkflow}\" /></dissemination>"
        registration_workflows = administrative.registrationWorkflow.map { |wf_id| "<workflow id=\"#{wf_id}\" />" }.join
        admin_node.add_child "<registration>#{registration_workflows}</registration>"

        administrative_metadata.ng_xml_will_change!
      end
    end
  end
end
