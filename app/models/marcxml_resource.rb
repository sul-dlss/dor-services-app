# MARC resource model for retrieving and transforming MARC records
class MarcxmlResource
  MARC_TO_MODS_XSLT = Nokogiri::XSLT(File.read(File.join(Rails.root, 'app', 'xslt', 'MARC21slim2MODS3-6.xsl')))

  def self.find_by(catkey: nil, barcode: nil)
    if catkey
      new(catkey: catkey)
    elsif barcode
      solr = RSolr.connect(url: Settings.CATALOG.SOLR_URL)
      response = solr.get('barcode', params: { n: barcode })
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
    MARC_TO_MODS_XSLT.transform(Nokogiri::XML(marcxml)).to_xml
  end

  def marcxml
    Faraday.get(Settings.CATALOG.MARCXML_URL % { catkey: catkey }).body
  end
end
