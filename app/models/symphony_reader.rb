# frozen_string_literal: true

# Reader from symphony's JSON API to a MARC record
class SymphonyReader
  class ResponseError < StandardError; end

  attr_reader :catkey

  def self.client
    Faraday.new(headers: Settings.catalog.symphony.headers)
  end

  def initialize(catkey:)
    @catkey = catkey
  end

  def to_marc
    record = MARC::Record.new

    # note that new record already has default leader, but we don't want it unless it's from Symphony
    record.leader = leader

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

  # see https://symphony-webservices-dev.stanford.edu/symws/resource_Catalog_Bib.html for response info
  def symphony_response
    resp = client.get(format(Settings.catalog.symphony.json_url, catkey: catkey))

    if resp.status == 200
      validate_response(resp)
      return resp
    elsif resp.status == 404
      errmsg = "Record not found in Symphony: #{@catkey}"
    else
      errmsg = "Got HTTP Status-Code #{resp.status} retrieving #{@catkey} from Symphony: #{resp.body}"
      Honeybadger.notify(errmsg)
    end

    raise ResponseError, errmsg
  end

  # expects resp.status to be 200;  does not check response code
  def validate_response(resp)
    exp_content_length = resp.headers['Content-Length'].to_i
    actual_content_length = resp.body.length
    return resp if actual_content_length == exp_content_length

    errmsg = "Incomplete response received from Symphony for #{@catkey} - expected #{exp_content_length} bytes but got #{actual_content_length}"
    Honeybadger.notify(errmsg)
    raise ResponseError, errmsg
  end

  def json
    @json ||= JSON.parse(symphony_response.body)
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
