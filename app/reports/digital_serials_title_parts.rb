# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DigitalSerialsTitleParts.report(filename: '/opt/app/deploy/dor-services-app/druid_list.txt')" > digital_serials_title_parts.csv
class DigitalSerialsTitleParts
  # Report on title part names and part numbers for a provided set of druids.
  # The provided file contains a list of druids, one per line, without the 'druid:' prefix.
  # filename should be the full path.  There won't be shell expansion, so e.g. "~" for home dir won't work.
  def self.report(...)
    new(...).report
  end

  def initialize(filename:)
    @filename = filename
  end

  attr_reader :filename

  def report
    raise "Input file missing: #{filename}" unless File.exist?(filename)

    puts 'druid,catalogRecordId,part_names,part_numbers'
    File.foreach(filename) do |raw_line|
      druid = "druid:#{raw_line.chomp}"
      cocina_object = CocinaObjectStore.find(druid)
      catalog_record_ids = cocina_object.identification.catalogLinks.select { |link| link.catalog == 'folio' }.map(&:catalogRecordId)
      part_names = cocina_object.description.title.map(&:structuredValue).flatten.select { |part| part.type == 'part name' }.map(&:value)
      part_numbers = cocina_object.description.title.map(&:structuredValue).flatten.select { |part| part.type == 'part number' }.map(&:value)

      line = [
        druid,
        catalog_record_ids.join(';'),
        "\"#{part_names.join(';')}\"",
        "\"#{part_numbers.join(';')}\""
      ].join(',')

      puts "#{line}\n"
    rescue StandardError => e
      logger.error("Unexpected error for druid: #{e}")
    end
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log', "#{self.class.name}.log"))
  end
end
