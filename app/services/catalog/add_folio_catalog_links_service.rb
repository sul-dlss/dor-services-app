# frozen_string_literal: true

module Catalog
  # Adds Folio catalog links to cocina object based on symphony catalog links.
  # This is for use prior to switch over from folio. After that this should be
  # removed.
  class AddFolioCatalogLinksService
    def self.add(cocina_object)
      new(cocina_object).add
    end

    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    def add
      return cocina_object if cocina_object.admin_policy?
      return cocina_object if cocina_object.identification.catalogLinks.blank?

      cocina_object.new(identification: cocina_object.identification.new(catalogLinks: synced_catalog_links))
    end

    private

    attr_reader :cocina_object

    # The following catkeys are valid but are from Lane Medical Library records
    # that will not be migrated. They should remain in the record for now but
    # no HRIDs should be generated based on them.
    LANE_NOT_MIGRATING = %w[
      10872078
      10906003
      11574734
      11718696
      12208745
      12307427
      12718359
      12811199
      13638174
      11827181
      12311317
    ].freeze

    def synced_catalog_links
      catalog_links = []
      cocina_object.identification.catalogLinks.each do |catalog_link|
        next if non_lane_folio_link?(catalog_link)

        if migrate_catalog_link?(catalog_link)
          catalog_links << Cocina::Models::FolioCatalogLink.new(catalog: 'folio', catalogRecordId: "a#{catalog_link.catalogRecordId}",
                                                                refresh: catalog_link.refresh)
        end
        catalog_links << catalog_link
      end
      catalog_links
    end

    def non_lane_folio_link?(catalog_link)
      # Keep Lane folio catalog links (start with L)
      catalog_link.catalog == 'folio' && !catalog_link.catalogRecordId.start_with?('L')
    end

    def migrate_catalog_link?(catalog_link)
      catalog_link.catalog == 'symphony' && LANE_NOT_MIGRATING.exclude?(catalog_link.catalogRecordId)
    end
  end
end
