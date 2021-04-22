# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema for DROs
    class DROAccess
      def self.props(rights_metadata_ds, embargo_metadata_ds)
        new(rights_metadata_ds, embargo_metadata_ds).props
      end

      def initialize(rights_metadata_ds, embargo_metadata_ds)
        @rights_metadata_ds = rights_metadata_ds
        @embargo_metadata_ds = embargo_metadata_ds
      end

      def props
        {
          license: Access::License.find(rights_metadata_ds),
          copyright: Access::Copyright.find(rights_metadata_ds),
          useAndReproductionStatement: Access::UseStatement.find(rights_metadata_ds),
          embargo: Access::Embargo.props(embargo_metadata_ds)
        }
          .merge(Access::AccessRights.props(rights_metadata_ds.dra_object, rights_xml: rights_metadata_ds.to_xml))
          .compact
      end

      private

      attr_reader :embargo_metadata_ds, :rights_metadata_ds
    end
  end
end
