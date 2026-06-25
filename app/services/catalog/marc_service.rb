# frozen_string_literal: true

module Catalog
  # MARC service for retrieving and transforming MARC records
  class MarcService
    # @see #marc, #initialize
    def self.marc(...)
      new(...).marc
    end

    # @param barcode [String] barcode of the item
    # @param folio_instance_hrid [String] Folio instance HRID
    # @param create_marc_if_missing [Boolean] whether to create a MARC record if missing in the catalog (default: false)
    def initialize(barcode: nil, folio_instance_hrid: nil, create_marc_if_missing: false)
      @barcode = barcode
      @folio_instance_hrid = folio_instance_hrid || FolioClient.fetch_hrid(barcode:)
      @create_marc_if_missing = create_marc_if_missing
    end

    # @return [Hash] MARC record as a hash
    # @raise [Error]
    def marc
      marc_record ||= begin
        marc_hash = SourceStorageFetcher.fetch(folio_instance_hrid:)
        ControlFieldsTransformer.transform(marc_hash:, folio_instance_hrid:)
      rescue FolioClient::ResourceNotFound, FolioClient::MultipleResourcesFound
        raise Errors::RecordNotFoundError,
              "Catalog record not found for HRID '#{folio_instance_hrid}' or barcode '#{barcode}'"
        # raise e unless create_marc_if_missing

        # marc_record_from_catalog_instance_record
      end

      update_marc_cache!(marc_record:)

      marc_record.to_hash
    end

    private

    attr_reader :barcode, :create_marc_if_missing, :folio_instance_hrid

    def update_marc_cache!(marc_record:)
      return if marc_record.nil?

      # Cache the MARC, so that we can use it for creating the Argo index without having to fetch it again.
      MarcCacheEntry.upsert( # rubocop:disable Rails/SkipsModelValidations
        {
          folio_hrid: folio_instance_hrid,
          marc_data: marc_record.to_json_string
        },
        unique_by: :index_marc_cache_entries_on_folio_hrid
      )
    end
  end
end
