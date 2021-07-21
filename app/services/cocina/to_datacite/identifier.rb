# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description identifier and purl attributes to the DataCite identifer and alternateIdentifier attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Identifier
      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of DataCite identifier attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.identifier_attributes(cocina_desc)
        new(cocina_desc).identifier_attributes
      end

      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of DataCite alternateIdentifier attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.alternate_identifier_attributes(cocina_desc)
        new(cocina_desc).alternate_identifier_attributes
      end

      def initialize(cocina_desc)
        @cocina_desc = cocina_desc
      end

      # @return [Hash] Hash of DataCite identifier attributes, conforming to the expectations of HTTP PUT request to DataCite
      def identifier_attributes
        return if doi.blank?

        {
          identifier: doi,
          identifierType: 'DOI'
        }
      end

      # @return [Hash] Hash of DataCite alternateIdentifier attributes, conforming to the expectations of HTTP PUT request to DataCite
      def alternate_identifier_attributes
        return if purl.blank?

        {
          alternateIdentifier: purl,
          alternateIdentifierType: 'PURL'
        }
      end

      private

      attr :cocina_desc

      def purl
        @purl ||= cocina_desc.purl
      end

      def doi
        @doi ||= cocina_desc.identifier&.find { |cocina_identifier| cocina_identifier.type == 'DOI' }&.value
      end
    end
  end
end
