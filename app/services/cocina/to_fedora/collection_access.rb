# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the CollectionAccess schema to the
    # Fedora 3 data model rightsMetadata
    class CollectionAccess
      # @param [Dor::Collection] item
      # @param [Cocina::Models::CollectionAccess] access
      def self.apply(collection, access)
        new(collection, access).apply
      end

      def initialize(collection, access)
        @collection = collection
        @access = access
      end

      def apply
        return if access.nil?

        AccessGenerator.generate(root: collection.rightsMetadata.ng_xml.root, access: access)
        collection.rightsMetadata.copyright = access.copyright if access.copyright
        collection.rightsMetadata.use_statement = access.useAndReproductionStatement if access.useAndReproductionStatement
        License.update(collection.rightsMetadata, access.license) if access.license
        collection.rightsMetadata.ng_xml_will_change!
      end

      private

      attr_reader :collection, :access
    end
  end
end
