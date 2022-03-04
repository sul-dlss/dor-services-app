# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DROAccess schema to the
    # Fedora 3 data model rightsMetadata annd embargoMetadata
    class DROAccess
      # @param [Dor::Item] item
      # @param [Cocina::Models::DROAccess] access
      # @param [Cocina::Models::DROStructural] structural
      def self.apply(item, access, structural)
        new(item, access, structural).apply
      end

      def initialize(item, access, structural)
        @item = item
        @access = access
        @structural = structural
      end

      def apply
        return if access.nil?

        apply_rights

        EmbargoMetadataGenerator.generate(embargo: access&.embargo, embargo_metadata: item.embargoMetadata)
      end

      private

      attr_reader :item, :access, :structural

      def apply_rights
        AccessGenerator.generate(root: item.rightsMetadata.ng_xml.root, access: access, structural: structural)
        item.rightsMetadata.copyright = access.copyright
        # now remove any empty copyright elements
        item.rightsMetadata.ng_xml.root.xpath('//copyright[count(*) = 0]').each(&:remove)
        item.rightsMetadata.use_statement = access.useAndReproductionStatement
        License.update(item.rightsMetadata, access.license)
        item.rightsMetadata.ng_xml_will_change!
      end
    end
  end
end
