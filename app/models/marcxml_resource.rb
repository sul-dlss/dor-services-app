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
    marc_record.to_xml.to_s
  end

  private

  def symphony_client
    Faraday.new(headers: Settings.CATALOG.SYMPHONY.HEADERS)
  end

  def symphony_json
    JSON.parse(symphony_client.get(Settings.CATALOG.SYMPHONY.JSON_URL % { catkey: catkey }).body)
  end

  def marc_record
    @marc_record ||= begin
      record = MARC::Record.new
      data = symphony_json['fields']['bib']

      record.leader = data['leader']

      data['fields'].each do |field|
        if MARC::ControlField.control_tag? field['tag']
          record << MARC::ControlField.new(field['tag'], field['subfields'].first['data'])
        else
          f = MARC::DataField.new(field['tag'], field['inds'][0], field['inds'][1])
          field['subfields'].each do |subfield|
            f.append MARC::Subfield.new(subfield['code'], subfield['data'])
          end
          record << f
        end
      end

      record
    end
  end
end
