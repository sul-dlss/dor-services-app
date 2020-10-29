# frozen_string_literal: true

require 'active_support/gzip'

# Support local caching of DOR content (for validating cocina mappings)
class FedoraCache
  include Rubydora::FedoraUrlHelpers

  def connection
    @connection ||= Faraday::Connection.new(
      url: Settings.fedora_url,
      ssl: {
        client_cert: OpenSSL::X509::Certificate.new(File.read(Settings.ssl.cert_file)),
        client_key: OpenSSL::PKey.read(File.read(Settings.ssl.key_file))
      },
      headers: { 'Accept' => 'text/xml' }
    )
  end

  def cache_object(druid)
    cache_id = cache_id_for_object(druid)
    return if cached?(cache_id)

    resp = connection.get(object_url(druid, { format: 'xml' }))
    return if resp.status == 404

    raise "Getting object for #{druid} returned #{resp.status}" if resp.status != 200

    put_cache(cache_id, resp.body)
  end

  def object(druid)
    cache_id = cache_id_for_object(druid)
    get_cache(cache_id)
  end

  def cache_descmd(druid)
    cache_id = cache_id_for_descmd(druid)
    return if cached?(cache_id)

    resp = connection.get(datastream_content_url(druid, 'descMetadata', { format: 'xml' }))
    return if resp.status == 404

    raise "Getting descMetadata for #{druid} returned #{resp.status}" if resp.status != 200

    put_cache(cache_id, resp.body)
  end

  def descmd(druid)
    cache_id = cache_id_for_descmd(druid)
    get_cache(cache_id)
  end

  def descmd_xml(druid)
    Nokogiri::XML(descmd(druid))
  end

  def label(druid)
    ng_xml = Nokogiri::XML(object(druid))
    ng_xml.xpath('//xmlns:objLabel').first.text
  end

  private

  def cache_id_for_object(druid)
    "#{druid}-object"
  end

  def cache_id_for_descmd(druid)
    "#{druid}-descmd"
  end

  def cachepath_for(cache_id)
    "cache/#{cache_id[6..8]}/#{cache_id[9..11]}/#{cache_id}.gz"
  end

  def put_cache(cache_id, body)
    filepath = cachepath_for(cache_id)
    path = File.dirname(filepath)
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
    Zlib::GzipWriter.open(filepath) do |gz|
      gz.write body
    end
  end

  def cached?(cache_id)
    File.exist?(cachepath_for(cache_id))
  end

  def get_cache(cache_id)
    raise 'Missing item' unless cached?(cache_id)

    Zlib::GzipReader.open(cachepath_for(cache_id)).read
  end
end
