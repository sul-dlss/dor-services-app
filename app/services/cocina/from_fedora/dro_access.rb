# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema for DROs
    class DROAccess < Access
      def props
        super.tap do |access|
          embargo = build_embargo
          access[:embargo] = embargo unless embargo.empty?
          access[:useAndReproductionStatement] = item.rightsMetadata.use_statement.first if item.rightsMetadata.use_statement.first.present?
          access[:copyright] = item.rightsMetadata.copyright.first if item.rightsMetadata.copyright.first.present?
        end
      end

      private

      def build_embargo
        return {} unless item.embargoMetadata.release_date.any?

        {
          releaseDate: item.embargoMetadata.release_date.first.utc.iso8601,
          access: build_embargo_access
        }.tap do |embargo|
          embargo[:useAndReproductionStatement] = item.embargoMetadata.use_and_reproduction_statement.first if item.embargoMetadata.use_and_reproduction_statement.present?
        end
      end

      def build_embargo_access
        access_node = item.embargoMetadata.release_access_node.xpath('//access[@type="read"]/machine/*[1]').first
        return 'dark' if access_node.nil?
        return 'world' if access_node.name == 'world'
        return access_node.content if access_node.name == 'group'

        'dark'
      end
    end
  end
end
