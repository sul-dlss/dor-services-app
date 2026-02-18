# frozen_string_literal: true

module Catalog
  # MARC service for retrieving and transforming MARC records
  class MarcService
    class MarcServiceError < RuntimeError; end
    class CatalogResponseError < MarcServiceError; end
    class CatalogRecordNotFoundError < MarcServiceError; end

    # @see #initialize
    # @return [Hash] MARC Record as a hash
    def self.marc(...)
      new(...).marc
    end

    def initialize(barcode: nil, folio_instance_hrid: nil)
      @barcode = barcode
      @folio_instance_hrid = folio_instance_hrid
    end

    # @return [Nokogiri::XML::Document] MARCXML XML
    # @raise CatalogResponseError
    # @raise CatalogRecordNotFoundError
    def marcxml_ng
      @marcxml_ng ||= Nokogiri::XML(marc_record.to_xml.to_s)
    end

    # @return [MARC::Record] MARC record
    # @raise CatalogResponseError
    # @raise CatalogRecordNotFoundError
    def marc_record
      @marc_record ||= marc_record_from_folio
    end

    # @return [Hash] MARC record as a hash
    # @raise CatalogResponseError
    # @raise CatalogRecordNotFoundError
    def marc
      marc_record.to_hash
    end

    private

    attr_reader :barcode, :folio_instance_hrid

    def marc_record_from_folio
      FolioReader.to_marc(folio_instance_hrid:, barcode:)
    rescue FolioClient::ResourceNotFound
      raise CatalogRecordNotFoundError, "Catalog record not found. HRID: #{folio_instance_hrid} | Barcode: #{barcode}"
    rescue FolioClient::Error => e
      raise CatalogResponseError, "Error getting record from catalog: #{e.message}"
    end
  end
end
