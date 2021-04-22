# frozen_string_literal: true

module Cocina
  module FromFedora
    module Access
      # builds the Access subschema for DROs
      class Embargo
        def self.props(embargo_metadata_ds)
          new(embargo_metadata_ds).props
        end

        def initialize(embargo_metadata_ds)
          @embargo_metadata_ds = embargo_metadata_ds
        end

        def props
          return unless embargo_metadata_ds.release_date.any?
          return if embargo_metadata_ds.status != 'embargoed' # We don't need to map any released embargos

          {
            releaseDate: embargo_metadata_ds.release_date.first.utc.iso8601
          }.tap do |embargo|
            embargo[:useAndReproductionStatement] = embargo_metadata_ds.use_and_reproduction_statement.first if embargo_metadata_ds.use_and_reproduction_statement.present?
          end.merge(AccessRights.props(dor_rights_auth_object, rights_xml: embargo_metadata_ds.to_xml))
        end

        private

        attr_reader :embargo_metadata_ds

        def dor_rights_auth_object
          # Adapt the XML so that a DRA object can be used.
          access_xml = embargo_metadata_ds.ng_xml.search('access').to_xml
          xml = "<?xml version=\"1.0\"?><rightsMetadata>#{access_xml}</rightsMetadata>"
          Dor::RightsAuth.parse(Nokogiri::XML(xml), true)
        end
      end
    end
  end
end
