# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema
    class Access
      def initialize(rights_metadata_ds)
        @rights_metadata_ds = rights_metadata_ds
      end

      def props
        {
          license: License.find(rights_metadata_ds),
          copyright: copyright,
          useAndReproductionStatement: use_statement
        }.compact.merge(AccessHelper.props(dra_object: rights_metadata_ds.dra_object))
      end

      private

      attr_reader :rights_metadata_ds

      def rights_object
        rights_metadata_ds.dra_object
      end

      def copyright
        rights_metadata_ds.copyright.first.presence
      end

      def use_statement
        rights_metadata_ds.use_statement.first.presence
      end
    end
  end
end
