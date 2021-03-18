# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema for DROs
    class Embargo
      def self.props(embargo_metadata_ds)
        new(embargo_metadata_ds).props
      end

      def initialize(embargo_metadata_ds)
        @embargo_metadata_ds = embargo_metadata_ds
      end

      def props
        return {} unless embargo_metadata_ds.release_date.any?

        {
          releaseDate: embargo_metadata_ds.release_date.first.utc.iso8601,
          access: build_embargo_access
        }.tap do |embargo|
          embargo[:useAndReproductionStatement] = embargo_metadata_ds.use_and_reproduction_statement.first if embargo_metadata_ds.use_and_reproduction_statement.present?
        end
      end

      private

      attr_reader :embargo_metadata_ds

      def build_embargo_access
        access_node = embargo_metadata_ds.release_access_node.xpath('//access[@type="read"]/machine/*[1]').first
        return 'dark' if access_node.nil?
        return 'world' if access_node.name == 'world'
        return access_node.content if access_node.name == 'group'

        'dark'
      end
    end
  end
end
