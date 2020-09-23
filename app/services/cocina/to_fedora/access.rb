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

      # TODO: this should be expanded to support file level rights: https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=Rights+metadata+--+the+rightsMetadata+datastream
      #       See https://argo.stanford.edu/view/druid:bb142ws0723 as an example
      # @param [Dor::Item, Dor::Collection] item
      # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access
      def apply
        create_embargo(access.embargo) if access.is_a?(Cocina::Models::DROAccess) && access.embargo

        # See https://github.com/sul-dlss/dor-services/blob/master/lib/dor/datastreams/rights_metadata_ds.rb
        Dor::RightsMetadataDS.upd_rights_xml_for_rights_type(item.rightsMetadata.ng_xml, rights_type)
        item.rightsMetadata.ng_xml_will_change!
      end

      private

      attr_reader :item, :access

      def rights_type
        return 'cdl-stanford-nd'if access.is_a?(Cocina::Models::DROAccess) && access.controlledDigitalLending

        case access.access
        when 'location-based'
          "loc:#{access.readLocation}"
        when 'citation-only'
          'none'
        when 'dark'
          'dark'
        else
          access.download == 'none' ? "#{access.access}-nd" : access.access
        end
      end

      def create_embargo(embargo)
        EmbargoService.create(item: item,
                              release_date: embargo.releaseDate,
                              access: embargo.access,
                              use_and_reproduction_statement: embargo.useAndReproductionStatement)
      end
    end
  end
end
