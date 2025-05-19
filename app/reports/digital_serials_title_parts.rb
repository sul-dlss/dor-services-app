# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DigitalSerialsTitleParts.report(filename: '/opt/app/deploy/dor-services-app/druid_list.txt')"
class DigitalSerialsTitleParts
  # Report on title part names and part numbers for a provided set of druids.
  # Also generates a part label for each druid if one does not already exist in the catalogLinks.
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

    puts 'druid,catalogRecordId,part_names,part_numbers,part_label,sort_key'
    File.foreach(filename, chomp: true) do |druid|
      @cocina_object = CocinaObjectStore.find(druid)
      catalog_record_id = @cocina_object.identification.catalogLinks.find { |link| link.catalog == 'folio' }&.catalogRecordId
      @title = @cocina_object.description.title.first

      structured_part_names = []
      parallel_part_names = []
      structured_part_numbers = []
      parallel_part_numbers = []

      if @title.structuredValue.any?
        structured_part_names = @title.structuredValue.select { |part| part.type == 'part name' }.map(&:value)
        structured_part_numbers = @title.structuredValue.select { |part| part.type == 'part number' }.map(&:value)
      end

      if @title.parallelValue.any?
        parallel_part_names = @title.parallelValue.first.structuredValue.select { |part| part.type == 'part name' }.map(&:value)
        parallel_part_numbers = @title.parallelValue.first.structuredValue.select { |part| part.type == 'part number' }.map(&:value)
      end

      part_names = structured_part_names + parallel_part_names
      part_numbers = structured_part_numbers + parallel_part_numbers

      sort_key = @cocina_object.description.note.find { |note| note.type == 'date/sequential designation' }&.value

      line = [
        druid,
        catalog_record_id,
        "\"#{part_names.join(';')}\"",
        "\"#{part_numbers.join(';')}\"",
        "\"#{part_label}\"",
        "\"#{sort_key}\""
      ].join(',')

      puts "#{line}\n"
    rescue StandardError => e
      logger.error("Unexpected error for druid: #{e}")
    end
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log', "#{self.class.name}.log"))
  end

  # following methods copied or adapted from Catalog::Marc856Generator for generating part label
  def part_types
    ['part name', 'part number']
  end

  def part_label
    part_label_from_catalog_links || part_label_from_title
  end

  def part_label_from_catalog_links
    @cocina_object.identification&.catalogLinks&.find { |link| link.catalog == 'folio' }&.partLabel
  end

  def part_label_from_title
    # Need to check both structuredValue on title and in parallelValues
    structured_values = []
    structured_values << @title.structuredValue if @title.structuredValue.present?
    @title.parallelValue.each do |parallel_value|
      structured_values << parallel_value.structuredValue if parallel_value.structuredValue.present?
    end

    part_parts = []
    structured_values.each do |structured_value|
      structured_value.each do |part|
        part_parts << part if part_types.include?(part.type)
      end
    end

    part_parts.map.with_index do |part, index|
      # if the part is not the first one, check the previous part type to determine the delimiter
      delimiter = if index.positive? && part_parts[index - 1].type == 'part number'
                    ', '
                  elsif index.positive? && part_parts[index - 1].type == 'part name'
                    '. '
                  else
                    ''
                  end
      "#{delimiter}#{part.value}"
    end.join
  end
end
