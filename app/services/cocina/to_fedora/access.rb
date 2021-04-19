# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the Access schema to the
    # Fedora 3 data model rightsMetadata
    class Access
      # TODO: this should be expanded to support file level rights: https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=Rights+metadata+--+the+rightsMetadata+datastream
      #       See https://argo.stanford.edu/view/druid:bb142ws0723 as an example
      # @param [Dor::Item, Dor::Collection] item
      # @param [Cocina::Models::DROAccess, Cocina::Models::CollectionAccess] access
      def self.apply(item, access)
        new(item, access).apply
      end

      def initialize(item, access)
        @item = item
        @access = access
      end

      def apply
        RightsMetadataGenerator.generate(rights: rightsMetadata, access: access)
        update_rights_statements!
        License.update(rightsMetadata, access.license) if access.license
      end

      private

      attr_reader :item, :access

      delegate :rightsMetadata, to: :item

      def update_rights_statements!
        rightsMetadata.copyright = access.copyright if access.copyright
        rightsMetadata.use_statement = access.useAndReproductionStatement if access.useAndReproductionStatement
        rightsMetadata.ng_xml_will_change!
      end
    end
  end
end
