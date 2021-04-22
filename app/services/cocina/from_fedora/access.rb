# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema for Collections
    class Access
      def self.collection_props(rights_metadata_ds)
        props = new(rights_metadata_ds).props
        # Collection access does not have download
        props.delete(:download)
        props
      end

      def initialize(rights_metadata_ds)
        @rights_metadata_ds = rights_metadata_ds
      end

      def props
        {
          license: License.find(rights_metadata_ds),
          copyright: copyright,
          useAndReproductionStatement: use_statement
        }
          .merge(AccessRights.props(rights_metadata_ds.dra_object, rights_xml: rights_metadata_ds.to_xml))
          .compact
      end

      private

      attr_reader :rights_metadata_ds

      def copyright
        rights_metadata_ds.copyright.first.presence
      end

      def use_statement
        rights_metadata_ds.use_statement.first.presence
      end
    end
  end
end
