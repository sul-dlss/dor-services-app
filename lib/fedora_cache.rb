# frozen_string_literal: true

require 'dry/monads'
require 'zip'

# Support local caching of DOR content (for validating cocina mappings)
class FedoraCache
  include Rubydora::FedoraUrlHelpers
  include Dry::Monads[:result]

  DATASTREAMS = %w[descMetadata identityMetadata rightsMetadata contentMetadata geoMetadata embargoMetadata RELS-EXT].freeze

  def initialize(overwrite: false, cache_dir: nil)
    @overwrite = overwrite
    @cache_dir = cache_dir || ENV['FEDORA_CACHE'] || 'cache'
  end

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

  def cache(druid)
    return if cached?(druid) && !overwrite

    object = fetch_object(druid)
    return if object.nil?

    datastreams = {}
    DATASTREAMS.each do |dsid|
      datastream = fetch_datastream(druid, dsid)
      datastreams[dsid] = datastream if datastream
    end

    zip_path = zip_path_for(druid)
    path = File.dirname(zip_path)
    FileUtils.mkdir_p(path) unless Dir.exist?(path)

    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream('object.xml') { |file| file.write(object) }
      datastreams.each_pair { |dsid, datastream| zipfile.get_output_stream("#{dsid}.xml") { |file| file.write(datastream) } }
    end
  end

  def cached?(druid)
    File.exist?(zip_path_for(druid))
  end

  def label_and_desc_metadata(druid)
    result = get_cache(druid, only: ['object', 'descMetadata'])
    return result if result.failure?

    contents = result.value!
    return Failure() unless contents.key?('object') && contents.key?('descMetadata')

    Success([label_for(contents['object']), contents['descMetadata']])
  end

  def label_and_datastreams(druid)
    result = get_cache(druid)
    return result if result.failure?

    contents = result.value!
    Success([label_for(contents['object']), contents.except('object')])
  end

  def datastream(druid, dsid)
    result = get_cache(druid, only: [dsid])
    return result if result.failure?

    contents = result.value!
    return Failure() unless contents.key?(dsid)

    Success(contents[dsid])
  end

  private

  attr_reader :overwrite, :cache_dir

  def fetch_object(druid)
    resp = connection.get(object_url(druid, { format: 'xml' }))
    return if resp.status == 404

    raise "Getting object for #{druid} returned #{resp.status}" if resp.status != 200

    resp.body
  end

  def fetch_datastream(druid, dsid)
    resp = connection.get(datastream_content_url(druid, dsid, { format: 'xml' }))
    return if resp.status == 404

    raise "Getting #{dsid} for #{druid} returned #{resp.status}" if resp.status != 200

    resp.body
  end

  def zip_path_for(druid)
    id = druid.delete_prefix('druid:')
    "#{cache_dir}/#{id[0..2]}/#{id[3..5]}/#{id}.zip"
  end

  def get_cache(druid, only: nil)
    return Failure() unless cached?(druid)

    contents = {}
    Zip::File.open(zip_path_for(druid)) do |zip_file|
      zip_file.each do |entry|
        key = entry.name.delete_suffix('.xml')
        next unless only.nil? || only.include?(key)

        contents[key] = entry.get_input_stream.read
      end
    end

    Success(contents)
  end

  def label_for(object)
    ng_xml = Nokogiri::XML(object)
    ng_xml.xpath('//xmlns:objLabel').first.text
  end
end
