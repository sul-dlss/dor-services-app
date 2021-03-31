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
        item.rightsMetadata.copyright = access.copyright if access.copyright
        item.rightsMetadata.use_statement = access.useAndReproductionStatement if access.useAndReproductionStatement
        lookup_and_assign_license! if access.license
        item.rightsMetadata.ng_xml_will_change!
      end

      private

      attr_reader :item, :access

      def lookup_and_assign_license! # rubocop:disable Metrics/AbcSize
        initialize_license_fields!

        if Dor::CreativeCommonsLicenseService.key?(license_code)
          item.rightsMetadata.creative_commons = license_code
          item.rightsMetadata.creative_commons.uri = access.license
          item.rightsMetadata.creative_commons_human = Dor::CreativeCommonsLicenseService.property(license_code).label
        elsif Dor::OpenDataLicenseService.key?(license_code)
          item.rightsMetadata.open_data_commons = license_code
          item.rightsMetadata.open_data_commons.uri = access.license
          item.rightsMetadata.open_data_commons_human = Dor::OpenDataLicenseService.property(license_code).label
        elsif license_code == 'none'
          item.rightsMetadata.creative_commons = license_code
          item.rightsMetadata.creative_commons_human = 'no Creative Commons (CC) license'
        else
          raise ArgumentError, "'#{license_code}' is not a valid license code"
        end
      end

      def license_code
        license_codes.fetch(access.license)
      end

      def license_codes
        DefaultRights::LICENSE_CODES.merge(
          Cocina::FromFedora::Access::NONE_LICENSE_URI => 'none'
        )
      end

      def use_field
        item.rightsMetadata.find_by_terms(:use).first # rubocop:disable Rails/DynamicFindBy
      end

      def initialize_field!(field_name, root_term = item.rightsMetadata.ng_xml.root)
        item.rightsMetadata.add_child_node(root_term, field_name)
      end

      def initialize_license_fields!
        initialize_field!(:use) if use_field.blank?
        initialize_field!(:creative_commons, use_field) if item.rightsMetadata.creative_commons.blank?
        initialize_field!(:open_data_commons, use_field) if item.rightsMetadata.open_data_commons.blank?
      end
    end
  end
end
