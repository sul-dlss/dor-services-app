# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.access schema to the
    # Fedora 3 data model rightsMetadata
    class Access
      def self.apply(item, access)
        rights_type = case access.access
                      when 'location-based'
                        "loc:#{access.readLocation}"
                      when 'citation-only'
                        'none'
                      when 'dark'
                        'dark'
                      else
                        access.download == 'none' ? "#{access.access}-nd" : access.access
                      end

        # See https://github.com/sul-dlss/dor-services/blob/master/lib/dor/datastreams/rights_metadata_ds.rb
        Dor::RightsMetadataDS.upd_rights_xml_for_rights_type(item.rightsMetadata.ng_xml, rights_type)
        item.rightsMetadata.ng_xml_will_change!
      end
    end
  end
end
