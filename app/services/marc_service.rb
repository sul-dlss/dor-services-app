# frozen_string_literal: true

# MARC service for retrieving and transforming MARC records
class MarcService
  attr_reader :catkey, :barcode

  def self.mods(catkey: nil, barcode: nil)
    new(catkey: catkey, barcode: barcode).mods
  end

  def self.marcxml(catkey: nil, barcode: nil)
    new(catkey: catkey, barcode: barcode).marcxml
  end

  def initialize(catkey: nil, barcode: nil)
    @catkey = catkey
    @barcode = barcode
  end

  # @raises SymphonyReader::ResponseError
  def mods
    marc_to_mods_xslt.transform(Nokogiri::XML(marcxml)).to_xml
  end

  # @raises SymphonyReader::ResponseError
  def marcxml
    marc_record.to_xml.to_s
  end

  private

  def marc_to_mods_xslt
    @marc_to_mods_xslt ||= Nokogiri::XSLT(File.open(File.join(Rails.root, 'app', 'xslt', 'MARC21slim2MODS3-7_SDR_v2-5.xsl')))
  end

  # @raises SymphonyReader::ResponseError
  def marc_record
    SymphonyReader.new(catkey: catkey, barcode: barcode).to_marc
  end
end
