# frozen_string_literal: true

# Determines which files should be shelved by comparing the current
# cocina object against PURL's current cocina object.
# A file should be shelved when it included in PURL's current cocina object
# or is included, but has changed.
class DigitalStacksDiffer
  class Error < StandardError; end

  def self.call(...)
    new(...).call
  end

  def initialize(cocina_object:)
    @cocina_object = cocina_object
  end

  # return [Array<String>] filenames of files that should be shelved
  def call
    cocina_object_file_map.reject do |_filename, md5|
      purl_file_md5s.include?(md5)
    end.keys
  end

  private

  attr_reader :cocina_object

  def bare_druid
    cocina_object.externalIdentifier.delete_prefix('druid:')
  end

  def purl_file_md5s
    @purl_file_md5s ||= purl_fetcher_reader.files_by_digest(bare_druid).map { |md5_file| md5_file.keys.first }.uniq
  rescue PurlFetcher::Client::NotFoundResponseError
    []
  rescue PurlFetcher::Client::ResponseError => e
    raise Error, "Unable to fetch file md5s from PURL Fetcher for #{bare_druid}: #{e.message}"
  end

  def purl_fetcher_reader
    PurlFetcher::Client::Reader.new(host: Settings.purl_fetcher.url)
  end

  # @return [Hash] map of filename to md5 for files that should be shelved
  def cocina_object_file_map
    return {} unless cocina_object.structural

    {}.tap do |file_map|
      cocina_object.structural.contains.each do |file_set|
        file_set.structural.contains.each do |file|
          file_map[file.filename] = md5_for(file) if file.administrative.shelve
        end
      end
    end
  end

  def md5_for(file)
    message_digest = file.hasMessageDigests.find { |digest| digest.type == 'md5' }
    raise Error, "Unable to find md5 for file #{file.externalIdentifier}" unless message_digest

    message_digest.digest
  end
end
