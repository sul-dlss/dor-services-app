# frozen_string_literal: true

module Cocina
  module ToFedora
    # Builds the rightsMetadata xml from cocina
    class RightsMetadataGenerator
      # @param [Dor::RightsMetadataDS] rights the DOR Rights metadata datastream
      # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access access/rights metadata in Cocina
      # @param [Cocina::Models::DROStructural] structural structural metadata in Cocina
      # @return [String] Fedora rights metadata XML
      def self.generate(rights:, access:, structural: nil)
        new(rights: rights, access: access, structural: structural).generate
      end

      # @param [Dor::RightsMetadataDS] rights the DOR Rights metadata datastream
      # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access access/rights metadata in Cocina
      # @param [Cocina::Models::DROStructural] structural structural metadata in Cocina
      def initialize(rights:, access:, structural:)
        @rights = rights
        @access = access
        @structural = structural
      end

      # @return [String] Fedora rights metadata XML
      def generate
        return if access.nil?

        rights.ng_xml_will_change!

        # Remove existing access nodes to begin rebuilding them from Cocina
        rights_xml.search('//rightsMetadata/access').each(&:remove)

        Rights::ObjectLevel.generate(rights_xml: rights_xml, access: access).each do |object_access_node|
          rights_xml.root.add_child(object_access_node)
        end

        Rights::FileLevel.generate(rights_xml: rights_xml, access: access, structural: structural).each do |file_access_node|
          rights_xml.root.add_child(file_access_node)
        end

        rights_xml.to_xml
      end

      private

      attr_reader :rights, :access, :structural

      def rights_xml
        rights.ng_xml
      end
    end
  end
end
