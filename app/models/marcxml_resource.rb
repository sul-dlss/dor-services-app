# frozen_string_literal: true

# MARC resource model for retrieving and transforming MARC records
class MarcxmlResource
  attr_reader :catkey, :barcode

  def initialize(params)
    @catkey = params[:catkey]
    @barcode = params[:barcode]
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
    @marc_to_mods_xslt ||= Nokogiri::XSLT(File.open(File.join(Rails.root, 'app', 'xslt', 'MARC21slim2MODS3-7_SDR_v2.xsl')))
  end

  # @raises SymphonyReader::ResponseError
  def marc_record
    SymphonyReader.new(catkey: catkey, barcode: barcode).to_marc
  end
end
