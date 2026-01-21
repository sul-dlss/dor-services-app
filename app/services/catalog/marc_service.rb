# frozen_string_literal: true

module Catalog
  # MARC service for retrieving and transforming MARC records
  class MarcService
    class MarcServiceError < RuntimeError; end
    class CatalogResponseError < MarcServiceError; end
    class CatalogRecordNotFoundError < MarcServiceError; end
    class TransformError < MarcServiceError; end

    def self.mods(barcode: nil, folio_instance_hrid: nil)
      new(barcode:, folio_instance_hrid:).mods
    end

    # @return [Hash] MARC Record as a hash
    def self.marc(barcode: nil, folio_instance_hrid: nil)
      new(barcode:, folio_instance_hrid:).marc
    end

    def initialize(barcode: nil, folio_instance_hrid: nil)
      @barcode = barcode
      @folio_instance_hrid = folio_instance_hrid
    end

    # @return [String] MODS XML
    # @raise CatalogResponseError
    def mods
      @mods ||= mods_ng.to_xml
    end

    # @return [Nokogiri::XML::Document] MODS XML
    # @raise CatalogResponseError
    # @raise CatalogRecordNotFoundError
    def mods_ng
      @mods_ng ||= begin
        marc_to_mods_xslt.transform(marcxml_ng)
      rescue RuntimeError => e
        raise TransformError, "Error transforming MARC to MODS: #{e.message}"
      end
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

    def marc_to_mods_xslt
      @marc_to_mods_xslt ||= Nokogiri::XSLT(File.open(Rails.root.join('app/xslt/MARC21slim2MODS3-7_SDR_v2-8.xsl')))
    end

    def marc_record_from_folio
      FolioReader.to_marc(folio_instance_hrid:, barcode:)
    rescue FolioClient::ResourceNotFound
      raise CatalogRecordNotFoundError, "Catalog record not found. HRID: #{folio_instance_hrid} | Barcode: #{barcode}"
    rescue FolioClient::Error => e
      raise CatalogResponseError, "Error getting record from catalog: #{e.message}"
    end
  end
end
