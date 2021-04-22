# frozen_string_literal: true

module Cocina
  module ToFedora
    # Builds the embargoMetadata xml from cocina
    class EmbargoMetadataGenerator
      # @param [Dor::EmbargoDS] embargo_metadata the DOR Embargo metadata datastream
      # @param [Cocina::Models::Embargo] embargo embargo metadata in Cocina
      def self.generate(embargo_metadata:, embargo:)
        new(embargo_metadata: embargo_metadata, embargo: embargo).generate
      end

      def initialize(embargo_metadata:, embargo:)
        @embargo_metadata = embargo_metadata
        @embargo = embargo
      end

      def generate
        return unless embargo&.releaseDate

        embargo_metadata.ng_xml_will_change!

        embargo_metadata.release_date = embargo.releaseDate
        embargo_metadata.status = 'embargoed'
        embargo_metadata.use_and_reproduction_statement = embargo.useAndReproductionStatement if embargo.useAndReproductionStatement

        AccessGenerator.generate(root: embargo_metadata.release_access_node, access: embargo)

        embargo_metadata.ng_xml.to_xml
      end

      private

      attr_reader :embargo_metadata, :embargo
    end
  end
end
