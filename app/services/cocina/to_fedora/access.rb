# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the Access schema to the
    # Fedora 3 data model rightsMetadata
    class Access
      # TODO: this should be expanded to support file level rights: https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=Rights+metadata+--+the+rightsMetadata+datastream
      #       See https://argo.stanford.edu/view/druid:bb142ws0723 as an example
      # @param [Dor::Item, Dor::Collection] item
      # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access
      def self.apply(item, access)
        new(item, access).apply
      end

      def initialize(item, access)
        @item = item
        @access = access
      end

      def apply
        # See https://github.com/sul-dlss/dor-services/blob/main/lib/dor/datastreams/rights_metadata_ds.rb
        Dor::RightsMetadataDS.upd_rights_xml_for_rights_type(item.rightsMetadata.ng_xml, Rights.rights_type(access))
        # This invalidates the dra_object, which is necessary if re-mapping.
        item.rightsMetadata.content = item.rightsMetadata.ng_xml.to_s
        item.rightsMetadata.ng_xml_will_change!
      end

      private

      attr_reader :item, :access
    end
  end
end
