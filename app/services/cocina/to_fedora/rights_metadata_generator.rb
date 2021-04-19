# frozen_string_literal: true

module Cocina
  module ToFedora
    # Builds the rightsMetadata xml from cocina
    class RightsMetadataGenerator
      # @param [Dor::RightsMetadataDS] rights the DOR Rights metadata datastream
      # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access access/rights metadata in Cocina
      def self.generate(rights:, access:)
        new(rights: rights, access: access).generate
      end

      def initialize(rights:, access:)
        @rights = rights
        @access = access
      end

      # Adapted copypasta from https://github.com/sul-dlss/dor-services/blob/main/lib/dor/datastreams/rights_metadata_ds.rb
      def generate
        rights.ng_xml_will_change!

        AccessGenerator.generate(root: rights.ng_xml.root, access: access)

        rights.ng_xml.to_xml
      end

      private

      attr_reader :rights, :access
    end
  end
end
