# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps Access to the cocina model
    class Access
      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      # @param [MARC::Record] marc MARC record from FOLIO
      def initialize(marc:)
        @marc = marc
      end

      # @return [Hash] a hash that can be mapped to a cocina model
      def build
        urls = marc.fields.filter_map { url_for(it) if it.tag == '856' }
        { url: urls, physicalLocation: physical_location }.compact_blank
      end

      private

      def physical_location
        field = marc['099']
        return unless field && field['a'].present?

        [{
          value: field['a'],
          type: 'shelf locator'
        }]
      end

      def url_for(field)
        return if field.indicator2 == '2'
        return if field['u'].blank?

        notes = Util.subfield_values(field, %w[y z]).map { |value| { value: value } }
        { displayLabel: field['3'], value: field['u'], note: notes }.compact_blank
      end

      attr_reader :marc
    end
  end
end
