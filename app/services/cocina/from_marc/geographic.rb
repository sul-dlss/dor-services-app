# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps Geographic to the cocina model
    class Geographic
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
        field = marc['034']
        return unless field

        [{ subject: [
          {
            type: 'bounding box coordinates',
            structuredValue: [
              { value: field['d'], type: 'west' },
              { value: field['e'], type: 'east' },
              { value: field['f'], type: 'north' },
              { value: field['g'], type: 'south' }
            ]
          }
        ] }]
      end

      private

      attr_reader :marc
    end
  end
end
