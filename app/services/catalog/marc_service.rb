# frozen_string_literal: true

module Catalog
  # MARC service for retrieving and transforming MARC records
  class MarcService
    class MarcServiceError < RuntimeError; end

    class CatalogResponseError < MarcServiceError; end
    class CatalogRecordNotFoundError < MarcServiceError; end
    class TransformError < MarcServiceError; end

    def self.mods(catkey: nil, barcode: nil, folio_instance_hrid: nil)
      new(catkey:, barcode:, folio_instance_hrid:).mods
    end

    def self.marcxml(catkey: nil, barcode: nil, folio_instance_hrid: nil)
      new(catkey:, barcode:, folio_instance_hrid:).marcxml
    end

    def initialize(catkey: nil, barcode: nil, folio_instance_hrid: nil)
      @catkey = catkey
      @barcode = barcode
      @folio_instance_hrid = folio_instance_hrid
    end

    # @return [String] MODS XML
    # @raises CatalogResponseError
    def mods
      mods_ng.to_xml
    end

    # @return [Nokogiri::XML::Document] MODS XML
    # @raises CatalogResponseError
    # @raises CatalogRecordNotFoundError
    def mods_ng
      marc_xml = marcxml_ng
      begin
        marc_to_mods_xslt.transform(marc_xml)
      rescue RuntimeError => e
        raise TransformError, "Error transforming MARC to MODS: #{e.message}"
      end
    end

    # @return [String] MARCXML XML
    # @raises CatalogResponseError
    # @raises CatalogRecordNotFoundError
    def marcxml
      marcxml_ng.to_xml
    end

    # @return [Nokogiri::XML::Document] MARCXML XML
    # @raises CatalogResponseError
    # @raises CatalogRecordNotFoundError
    def marcxml_ng
      Nokogiri::XML(marc_record.to_xml.to_s)
    end

    # @return [MARC::Record] MARC record
    # @raises CatalogResponseError
    # @raises CatalogRecordNotFoundError
    def marc_record
      if Settings.enabled_features.read_folio
        marc_record_from_folio
      else
        marc_record_from_symphony
      end
    end

    private

    attr_reader :catkey, :barcode, :folio_instance_hrid

    def marc_to_mods_xslt
      @marc_to_mods_xslt ||= Nokogiri::XSLT(File.open(Rails.root.join('app', 'xslt', 'MARC21slim2MODS3-7_SDR_v2-7.xsl')))
    end

    def marc_record_from_symphony
      SymphonyReader.new(catkey:, barcode:).to_marc
    rescue SymphonyReader::NotFound
      raise CatalogRecordNotFoundError, "Catalog record not found. Catkey: #{catkey} | Barcode: #{barcode}"
    rescue SymphonyReader::ResponseError => e
      raise CatalogResponseError, "Error getting record from catalog: #{e.message}"
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
