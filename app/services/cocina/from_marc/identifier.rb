# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps identifiers
    class Identifier
      # @param [MARC::Record] marc MARC record from FOLIO
      # @return [Hash] a hash that can be mapped to a cocina model
      def self.build(marc:)
        new(marc:).build
      end

      def initialize(marc:)
        @marc = marc
      end

      def build
        [lccn, isbn, issn, other_identifier, publisher_number].flatten.compact
      end

      OTHER_IDENTIFER_TYPES = {
        '0' => 'ISRC',
        '1' => 'UPC',
        '2' => 'ISMN',
        '3' => 'International Article Number',
        '4' => 'SICI'
      }.freeze

      PUBLISHER_NUMBER_TYPES = {
        '0' => 'issue number',
        '1' => 'matrix number',
        '2' => 'music plate',
        '3' => 'music publisher',
        '4' => nil
      }.freeze

      private

      def lccn
        field = marc['010']
        return unless field

        parts = values_for(field, %w[a])
        { value: parts.join(' '), type: 'LCCN' } if parts.any?
      end

      def isbn
        field = marc['020']
        return unless field

        parts = values_for(field, %w[a q])

        { value: parts.join(' '), type: 'ISBN' } if parts.any?
      end

      def issn
        field = marc['022']
        return unless field

        parts = values_for(field, %w[a])

        { value: parts.join(' '), type: 'ISSN' } if parts.any?
      end

      def other_identifier
        field = marc['024']
        return unless field

        parts = values_for(field, %w[a d q])
        return unless parts.any?

        if field.indicator1 == '7'
          code = field.subfields.find { it.code == '2' }.value
          code == 'doi' ? { value: parts.join(' '), type: 'DOI' } : { value: parts.join(' '), source: { code: } }
        elsif (type = OTHER_IDENTIFER_TYPES[field.indicator1])
          { value: parts.join(' '), type: }
        end
      end

      def publisher_number
        fields = marc.fields.select { it.tag == '028' }

        fields.map do |field|
          parts = values_for(field, %w[a b q])

          { value: parts.join(' '), type: PUBLISHER_NUMBER_TYPES.fetch(field.indicator1) }.compact_blank if parts.any?
        end
      end

      def values_for(field, subfields)
        field.subfields.select { |sf| subfields.include? sf.code }.map { it.value.strip }
      end

      attr_reader :marc
    end
  end
end
