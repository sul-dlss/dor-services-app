# frozen_string_literal: true

# MARC resource model for retrieving and transforming MARC records
class MarcxmlResource
  def self.find_by(catkey: nil, barcode: nil)
    if catkey
      new(catkey: catkey)
    elsif barcode
      solr = RSolr.connect(url: Settings.CATALOG.SOLR_URL)
      response = solr.get('barcode', params: { n: barcode }).with_indifferent_access
      catkey = response[:response][:docs].first[:id]

      new(catkey: catkey)
    else
      raise ArgumentError, 'Must supply either a catkey or barcode'
    end
  end

  attr_reader :catkey

  def initialize(catkey:)
    @catkey = catkey
  end

  def mods
    marc_to_mods_xslt.transform(Nokogiri::XML(marcxml)).to_xml
  end

  def marcxml
    marc_record.to_xml.to_s
  end

  private

  def marc_to_mods_xslt
    @marc_to_mods_xslt ||= Nokogiri::XSLT(File.open(File.join(Rails.root, 'app', 'xslt', 'MARC21slim2MODS3-6_SDR_v1.xsl')))
  end

  def marc_record
    SymphonyReader.new(catkey: catkey).to_marc
  end
end
