# frozen_string_literal: true

# Reader from symphony's JSON API to a MARC record
class SymphonyReader
  attr_reader :catkey

  def self.client
    Faraday.new(headers: Settings.CATALOG.SYMPHONY.HEADERS)
  end

  def initialize(catkey:)
    @catkey = catkey
  end

  def to_marc
    record = MARC::Record.new

    record.leader = leader if leader

    fields.uniq.each do |field|
      record << marc_field(field) unless %w[001 003].include? field['tag'] # explicitly remove all 001 and 003 fields from the record
    end

    # explicitly inject the catkey into the 001 field
    record << marc_field('tag' => '001', 'subfields' => [{ 'code' => '_', 'data' => "a#{catkey}" }])

    # explicitly inject SIRSI into the 003 field
    record << marc_field('tag' => '003', 'subfields' => [{ 'code' => '_', 'data' => 'SIRSI' }])

    record
  end

  private

  def client
    self.class.client
  end

  def json
    @json ||= JSON.parse(client.get(Settings.CATALOG.SYMPHONY.JSON_URL % { catkey: catkey }).body)
  end

  def bib_record
    return {} unless json['fields'] && json['fields']['bib']

    json['fields']['bib']
  end

  def leader
    bib_record['leader']
  end

  def fields
    bib_record.fetch('fields', [])
  end

  def marc_field(field)
    if MARC::ControlField.control_tag? field['tag']
      marc_control_field(field)
    else
      marc_data_field(field)
    end
  end

  def marc_control_field(field)
    MARC::ControlField.new(field['tag'], field['subfields'].first['data'])
  end

  def marc_data_field(field)
    f = MARC::DataField.new(field['tag'], field['inds'][0], field['inds'][1])
    field['subfields'].each do |subfield|
      f.append MARC::Subfield.new(subfield['code'], subfield['data'])
    end
    f
  end
end
