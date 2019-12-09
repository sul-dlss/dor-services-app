# frozen_string_literal: true

# A client for talking to sdr-services-app
class SdrClient
  extend Deprecation
  self.deprecation_horizon = 'dor-services-app version 4.0'

  # @raises [Dor::Exception] if SDR doesn't know about the object (i.e. 404 response code)
  # @raises [StandardError] if the response from SDR can't be parsed
  def self.current_version(druid)
    new(druid).current_version(parsed: true)
  end

  def initialize(druid)
    @druid = druid
  end

  # @return [Faraday::Response] with body of cm-inv-diff as xml
  def content_diff(current_content:, subset:, version: nil)
    Honeybadger.notify('dor-services-app deprecated method `SdrClient.content_diff` called. Use preservation-client content_diff instead.')
    query_params = { subset: subset }
    query_params[:version] = version unless version.nil?
    query_string = URI.encode_www_form(query_params)
    path = "/objects/#{druid}/cm-inv-diff"
    uri = sdr_uri(path)
    sdr_conn(uri).post("#{uri.path}?#{query_string}", current_content, 'Content-Type' => 'application/xml')
  end
  deprecation_deprecate content_diff: 'Use preservation-client content_inventory_diff or shelve_content_diff in caller instead.'

  def manifest(ds_name:)
    sdr_get("/objects/#{druid}/manifest/#{ds_name}")
  end

  def metadata(ds_name:)
    sdr_get("/objects/#{druid}/metadata/#{ds_name}")
  end

  def current_version(parsed: false)
    Honeybadger.notify('dor-services-app deprecated method `SdrClient.current_version` called. Use preservation-client current_version instead.')
    path = "/objects/#{druid}/current_version"
    response = sdr_get(path)
    return response unless parsed

    if response.status == 404
      raise Dor::Exception, 'SDR is not yet answering queries about this object. ' \
      "We've seen that when an object has been transferred, SDR isn't immediately ready to answer queries"
    end

    begin
      doc = Nokogiri::XML response.body
      raise if doc.root.name != 'currentVersion'

      return Integer(doc.text)
    rescue StandardError
      raise "Unable to parse XML from SDR current_version API call.\n\turl: #{sdr_uri(path)}\n\tstatus: #{response.status}\n\tbody: #{response.body}"
    end
  end
  deprecation_deprecate current_version: 'Use preservation-client current_version in caller instead.'

  def file_content(version:, filename:)
    query_string = URI.encode_www_form(version: version.to_s)
    encoded_filename = CGI.escape(filename)
    sdr_get("/objects/#{druid}/content/#{encoded_filename}?#{query_string}")
  end

  private

  attr_reader :druid

  def current_version_path
    "/objects/#{druid}/current_version"
  end

  def sdr_uri(path)
    URI("#{Settings.sdr_url}#{path}")
  end

  def sdr_conn(uri)
    Faraday.new("#{uri.scheme}://#{uri.host}").tap do |conn|
      conn.basic_auth(uri.user, uri.password)
    end
  end

  def sdr_get(path)
    uri = sdr_uri(path)
    sdr_conn(uri).get("#{uri.path}?#{uri.query}")
  end
end
