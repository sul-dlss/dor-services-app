# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the defaultAccess subschema for APOs
    class APOAccess
      def self.props(default_object_rights_ds)
        new(default_object_rights_ds).props
      end

      def initialize(default_object_rights_ds)
        @rights_metadata_ds = Dor::RightsMetadataDS.from_xml(default_object_rights_ds.content)
      end

      def props
        {
          license: Access::License.find(rights_metadata_ds),
          copyright: Access::Copyright.find(rights_metadata_ds),
          useAndReproductionStatement: Access::UseStatement.find(rights_metadata_ds)
        }
          .merge(Access::AccessRights.props(rights_metadata_ds.dra_object, rights_xml: rights_metadata_ds.to_xml))
          .compact
      end

      private

      attr_reader :rights_metadata_ds
    end
  end
end
