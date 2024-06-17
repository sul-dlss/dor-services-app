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
    cocina_object_file_map.reject do |filename, sha1|
      purl_cocina_object_file_map[filename] == sha1
    end.keys
  end

  private

  attr_reader :cocina_object

  def cocina_object_file_map
    @cocina_object_file_map ||= file_map_for(cocina_object.structural)
  end

  def purl_cocina_object_file_map
    @purl_cocina_object_file_map ||= file_map_for(purl_cocina_object_structural)
  end

  def purl_cocina_object_structural
    @purl_cocina_object_structural ||= begin
      response = connection.get("/#{bare_druid}.json")

      if response.success?
        Cocina::Models::DROStructural.new(JSON.parse(response.body)['structural'])
      elsif response.status == 404
        nil
      else
        raise Error, "Unable to fetch cocina object from PURL for #{bare_druid}: #{response.status}"
      end
    end
  end

  def bare_druid
    cocina_object.externalIdentifier.delete_prefix('druid:')
  end

  def connection
    @connection ||= Faraday.new(url: Purl.base_url)
  end

  # @return [Hash] map of filename to sha1 for files that should be shelved
  def file_map_for(cocina_object_structural)
    return {} unless cocina_object_structural

    {}.tap do |file_map|
      cocina_object_structural.contains.each do |file_set|
        file_set.structural.contains.each do |file|
          file_map[file.filename] = sha1_for(file) if file.administrative.shelve
        end
      end
    end
  end

  def sha1_for(file)
    message_digest = file.hasMessageDigests.find { |digest| digest.type == 'sha1' }
    raise Error, "Unable to find sha1 for file #{file.externalIdentifier}" unless message_digest

    message_digest.digest
  end
end
