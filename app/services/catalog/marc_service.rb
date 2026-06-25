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
    # @raise [Errors:BaseError]
    def marc # rubocop:disable Metrics/AbcSize
      marc_record = begin
        FolioClient.fetch_marc_hash(instance_hrid: folio_instance_hrid)
                   .then { |record_hash| AbstractNormalizer.normalize(record_hash:) }
                   .then { |record_hash| ControlFieldNormalizer.normalize(record_hash:, folio_instance_hrid:) }
                   .then { |record_hash| MARC::Record.new_from_hash(record_hash) }
      rescue FolioClient::ResourceNotFound, FolioClient::MultipleResourcesFound
        error_message = "Catalog record not found for HRID '#{folio_instance_hrid}' or barcode '#{barcode}'"
        raise Errors::RecordNotFoundError, error_message unless create_marc_if_missing

        FolioClient.fetch_instance_info(hrid: folio_instance_hrid)
                   .then { |instance_hash| InstanceMarcBuilder.build(instance_hash:) }
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
