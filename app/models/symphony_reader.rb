# frozen_string_literal: true

# Reader from symphony's JSON API to fetch marcxml given a catkey, or fetch a catkey given a barcode
class SymphonyReader
  class ResponseError < StandardError; end

  attr_reader :catkey, :barcode

  def self.client
    Faraday.new(headers: Settings.catalog.symphony.headers)
  end

  def initialize(catkey: nil, barcode: nil)
    @catkey = catkey
    @barcode = barcode
  end

  def fetch_catkey
    return nil unless barcode_json['fields'] && barcode_json['fields']['bib']

    barcode_json['fields']['bib']['key']
  end

  # @raises ResponseError
  def to_marc
    @catkey = fetch_catkey if catkey.nil? # we need a catkey to do this lookup, so fetch it from the barcode if none exists

    record = MARC::Record.new

    # NOTE: that new record already has default leader, but we don't want it unless it's from Symphony
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

  # see https://symphony-webservices-dev.stanford.edu/symws/sdk.html for documentation of symphony web services

  def client
    self.class.client
  end

  def fetch_barcode_response
    raise 'no barcode supplied' unless barcode

    url = Settings.catalog.symphony.base_url + Settings.catalog.symphony.barcode_path
    symphony_response(format(url, barcode: barcode))
  end

  def fetch_marc_response
    raise 'no catkey supplied' unless catkey

    url = Settings.catalog.symphony.base_url + Settings.catalog.symphony.marcxml_path
    symphony_response(format(url, catkey: catkey))
  end

  def symphony_response(url)
    resp = client.get(url)

    if resp.status == 200
      validate_response(resp)
      return resp
    elsif resp.status == 404
      # 404 received here is for the catkey, but this app cares about the druid
      #   for the DOR object, hence raising 404 from here could be misleading
      errmsg = "Record not found in Symphony. API call: #{url}"
    else
      errmsg = "Got HTTP Status-Code #{resp.status} calling #{url}: #{resp.body}"
    end

    raise ResponseError, errmsg
  rescue Faraday::TimeoutError => e
    errmsg = "Timeout for Symphony response for API call #{url}: #{e}"
    Honeybadger.notify(errmsg)
    raise ResponseError, errmsg
  end

  # expects resp.status to be 200;  does not check response code
  def validate_response(resp)
    # The length for a chunked response is 0, so checking it isn't meaningful.
    return resp if resp.headers['Transfer-Encoding'] == 'chunked'

    exp_content_length = resp.headers['Content-Length'].to_i
    actual_content_length = resp.body.length
    return resp if actual_content_length == exp_content_length

    errmsg = "Incomplete response received from Symphony for #{@catkey} - expected #{exp_content_length} bytes but got #{actual_content_length}"
    Honeybadger.notify(errmsg)
    raise ResponseError, errmsg
  end

  # @raises ResponseError
  def marc_json
    @marc_json ||= JSON.parse(fetch_marc_response.body)
  end

  # @raises ResponseError
  def barcode_json
    @barcode_json ||= JSON.parse(fetch_barcode_response.body)
  end

  # @raises ResponseError
  def bib_record
    return {} unless marc_json['fields'] && marc_json['fields']['bib']

    marc_json['fields']['bib']
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
