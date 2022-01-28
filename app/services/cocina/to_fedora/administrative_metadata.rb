# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the AdminPolicyAdministrative schema to the
    # Fedora 3 data model rights
    class AdministrativeMetadata
      def self.write(administrative_metadata, administrative)
        new(administrative_metadata, administrative).write
      end

      def initialize(administrative_metadata, administrative)
        @administrative_metadata = administrative_metadata
        @administrative = administrative
      end

      attr_reader :administrative_metadata, :administrative

      def write
        clear_nodes
        add_dissemination_nodes
        add_registration_nodes
        administrative_metadata.ng_xml_will_change!
      end

      def clear_nodes
        admin_node.xpath('registration/workflow|registration/collection|dissemination/workflow').each(&:remove)
      end

      def add_dissemination_nodes
        return unless administrative.disseminationWorkflow

        dissemination_node = admin_node.xpath('dissemination').first || admin_node.add_child('<dissemination/>').first
        dissemination_node.add_child "<workflow id=\"#{administrative.disseminationWorkflow}\" />"
      end

      def add_registration_nodes
        return if administrative.registrationWorkflow.blank?

        registration_node = admin_node.xpath('registration').first || admin_node.add_child('<registration/>').first
        Array(administrative.registrationWorkflow).each do |wf_id|
          registration_node.add_child "<workflow id=\"#{wf_id}\" />"
        end
        Array(administrative.collectionsForRegistration).each do |collection|
          registration_node.add_child "<collection id=\"#{collection}\" />"
        end
      end

      def admin_node
        @admin_node ||= administrative_metadata.ng_xml.xpath('//administrativeMetadata').first
      end
    end
  end
end
