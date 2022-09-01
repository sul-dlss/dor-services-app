# frozen_string_literal: true

# MARC service for retrieving and transforming MARC records
class MarcService
  class MarcServiceError < RuntimeError; end

  class CatalogResponseError < MarcServiceError; end
  class CatalogRecordNotFoundError < MarcServiceError; end
  class TransformError < MarcServiceError; end

  def self.mods(catkey: nil, barcode: nil)
    new(catkey:, barcode:).mods
  end

  def self.marcxml(catkey: nil, barcode: nil)
    new(catkey:, barcode:).marcxml
  end

  def initialize(catkey: nil, barcode: nil)
    @catkey = catkey
    @barcode = barcode
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
    SymphonyReader.new(catkey:, barcode:).to_marc
  rescue SymphonyReader::NotFound
    raise CatalogRecordNotFoundError, "Catalog record not found. Catkey: #{catkey} | Barcode: #{barcode}"
  rescue SymphonyReader::ResponseError => e
    raise CatalogResponseError, "Error getting record from catalog: #{e.message}"
  end

  private

  attr_reader :catkey, :barcode

  def marc_to_mods_xslt
    @marc_to_mods_xslt ||= Nokogiri::XSLT(File.open(File.join(Rails.root, 'app', 'xslt', 'MARC21slim2MODS3-7_SDR_v2-7.xsl')))
  end
end
