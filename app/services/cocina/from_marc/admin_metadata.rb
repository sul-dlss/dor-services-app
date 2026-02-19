# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps AdminMetadata to the cocina model
    class AdminMetadata
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
        { contributor:, event:, identifier:, note: }.compact_blank
      end

      private

      def contributor
        field = marc['040']
        return unless field && field['a']

        [{
          type: 'organization',
          name: [{ code: field['a'], source: { code: 'marcorg' } }]
        }]
      end

      def event
        [creation, modification].compact
      end

      def creation
        field = marc['008']
        return unless field

        {
          type: 'creation',
          date: [{ value: field.value[0..5], encoding: { code: 'marc' } }]
        }
      end

      def modification
        field = marc['005']
        return unless field

        {
          type: 'modification',
          date: [{ value: field.value[0..7], encoding: { code: 'iso8601' } }]
        }
      end

      def identifier
        field = marc['001']
        return unless field

        [{ value: field.value, type: 'FOLIO' }]
      end

      def note
        [{ value: "Converted from MARC to Cocina #{Time.zone.today.iso8601}", type: 'record origin' }]
      end

      attr_reader :marc
    end
  end
end
