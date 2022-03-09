# frozen_string_literal: true

require 'zlib'

# Archive Fedora Objects as FOXML to a druid-tree
class FedoraArchiver
  include Rubydora::FedoraUrlHelpers

  def initialize(druids:, archive_dir:, lenient:)
    @druids = druids
    @lenient = lenient
    @archive_dir = Pathname.new archive_dir
  end

  def run
    druids.map do |druid|
      write_foxml(druid, archive_dir)
      yield druid
    end
  end

  private

  attr_reader :druids, :archive_dir, :lenient

  def write_foxml(druid, archive_dir)
    obj_file = archive_dir + "#{dtree(druid)}.xml.gz"
    obj_dir = obj_file.dirname

    if obj_file.file?
      Rails.logger.info("#{druid} already found at #{obj_file}")
      return
    end

    begin
      content = fetch_foxml(druid)
      if content
        FileUtils.mkdir_p obj_dir
        Zlib::GzipWriter.open(obj_file) do |gzip_file|
          gzip_file.write(content)
        end
        Rails.logger.info("saved #{druid} as #{obj_file}")
      end
    rescue Faraday::TimeoutError
      FileUtils.rm(obj_file) if obj_file.file?
      msg = "timeout error when fetching #{druid}"
      Rails.logger.error(msg)
      raise msg unless lenient
    rescue StandardError => e
      FileUtils.rm(obj_file) if obj_file.file?
      raise e
    end
  end

  def fetch_foxml(druid)
    resp = connection.get(export_object_url(druid, { context: 'archive' }))
    if resp.status != 200
      msg = "getting #{druid} returned #{resp.status}"
      Rails.logger.error(msg)
      return if lenient

      raise msg
    end
    resp.body
  end

  def dtree(druid)
    id = druid.delete_prefix('druid:')
    "#{id[0..2]}/#{id[3..5]}/#{id}"
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
end
