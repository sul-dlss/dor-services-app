# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema for DROs
    class DROAccess < Access
      def self.props(rights_metadata_ds, embargo:)
        new(rights_metadata_ds, embargo: embargo).props
      end

      def initialize(rights_metadata_ds, embargo:)
        super(rights_metadata_ds)
        @embargo = embargo
      end

      def props
        super.tap do |access|
          access[:embargo] = embargo unless embargo.empty?
        end
      end

      private

      attr_reader :embargo
    end
  end
end
