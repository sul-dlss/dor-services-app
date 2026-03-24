# frozen_string_literal: true

module Catalog
  # Creates or updates FOLIO holdings record
  class HoldingsGenerator
    def self.manage_holdings(...)
      new(...).manage_holdings
    end

    # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    def manage_holdings
      return if catalog_record_id.blank?

      # Update the existing SDR holding if there is one
      if sdr_holding.present?
        update_holding
      # Only create a holdings record if this object is being released.
      elsif PublicMetadataReleaseTagService.released_to_searchworks?(cocina_object:)
        create_from_holdings
      end
    end

    def create_from_holdings
      instance_id = FolioClient.fetch_external_id(hrid: catalog_record_id)
      holdings_record = {
        'instance_id' => instance_id,
        'permanent_location_id' => sdr_location,
        'source_id' => 'f32d531e-df79-46b3-8932-cdd35f7a2264', # FOLIO
        'holdings_type_id' => '5684e4a3-9279-4463-b6ee-20ae21bbec07', # Electronic
        'discoverySuppress' => false
      }
      FolioClient.create_holdings(holdings_record: holdings_record)
    end

    private

    attr_reader :cocina_object

    def holdings
      @holdings ||= FolioClient.fetch_holdings(hrid: catalog_record_id)
    end

    def sdr_holding
      return nil if holdings.empty?

      @sdr_holding ||= fetch_sdr_holding(holdings: holdings)
    end

    def update_holding
      # Changes the holdings record discoverySuppress value and PUTs to FOLIO
      discovery_suppress = !PublicMetadataReleaseTagService.released_to_searchworks?(cocina_object:)
      # No need to update if the discoverySuppress value is already correct
      return if sdr_holding&.dig('discoverySuppress') == discovery_suppress

      sdr_holding['discoverySuppress'] = discovery_suppress
      FolioClient.update_holdings(holdings_id: sdr_holding['id'], holdings_record: sdr_holding)
    end

    # @param holdings [Array<Hash>] holdings records retrieved for the object's HRID
    # @return [Hash, nil] the holdings record for the object that has an SDR location, or nil
    def fetch_sdr_holding(holdings:)
      locations = Settings.catalog.folio.sdr_locations
      sdr_holdings = holdings.select do |holding|
        locations.any? do |_, location|
          location[:id] == holding['permanentLocationId']
        end
      end

      case sdr_holdings.size
      when 1
        sdr_holdings.first
      when 0
        nil
      else
        raise StandardError,
              "Multiple SDR holdings records found for #{cocina_object.externalIdentifier}: #{sdr_holdings}"
      end
    end

    def sdr_location
      # Find the first holding that has a location with a campus_id that matches one of the relevant campus ids.
      # If none of the holdings have a location with a matching campus_id, default to sul_sdr location id.
      holdings.each do |holding|
        location = FolioClient.fetch_location(location_id: holding['permanentLocationId'])
        Settings.catalog.folio.sdr_locations.each do |_, value| # rubocop:disable Style/HashEachMethods
          return value[:id] if location['campusId'] == value[:campus_id]
        end
      end
      # if no existing holdings have a location that matches our campus ids, default to sul_sdr location id
      Settings.catalog.folio.sdr_locations[:sul_sdr][:id]
    end

    # @return [String] catalog_record_id for the object
    def catalog_record_id
      cocina_object.identification.catalogLinks.find { |link| link.catalog == 'folio' }&.catalogRecordId
    end
  end
end
