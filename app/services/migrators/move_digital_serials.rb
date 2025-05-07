# frozen_string_literal: true

module Migrators
  # Used to move digital serials data from description to identification.catalogLinks
  class MoveDigitalSerials < Base
    # A migrator may provide a list of druids to be migrated (optional).
    def self.druids
      DRUIDS
    end

    # A migrator must implement a migrate? method that returns true if the SDR object should be migrated.
    def migrate?
      DRUIDS.include?(repository_object.external_identifier)
    end

    def migrate
      versions = [repository_object.head_version]

      if repository_object.open? && repository_object.last_closed_version.present?
        versions << repository_object.last_closed_version
      end

      versions.each do |version|
        migrate_version(version)
      end
    end

    def migrate_version(version)
      return if version.identification['catalogLinks'].blank?

      catalog_link = version.identification['catalogLinks'].find do |link|
        link['catalog'] == 'folio'
      end
      return unless catalog_link

      # create the partLabel if not already populated
      if catalog_link['partLabel'].blank?
        title = version.description['title'].first
        part_label = part_label_from_title(title)
        if part_label.present?
          catalog_link['partLabel'] = part_label
          delete_title_parts(title)
        end
      end
      # create the sortKey
      if catalog_link['sortKey'].blank? && version.description['note'].present?
        sort_note = version.description['note'].find do |note|
          note['type'] == 'date/sequential designation'
        end
        if sort_note.present?
          catalog_link['sortKey'] = sort_note['value']
          version.description['note'].delete(sort_note)
        end
      end

      return unless catalog_link['partLabel'] || catalog_link['sortKey']

      catalog_link['refresh'] = true
    end

    def part_types
      ['part name', 'part number']
    end

    def part_label_from_title(title)
      # Need to check both structuredValue on title and in parallelValue
      structured_values = []
      structured_values << title['structuredValue'] if title['structuredValue'].present?
      # should only check the first value in parallelValue and for a structuredValue
      if title['parallelValue'].present? && title['parallelValue'].first['structuredValue'].present?
        structured_values << title['parallelValue'].first['structuredValue']
      end

      part_parts = []
      structured_values.each do |structured_value|
        structured_value.each do |part|
          part_parts << part if part_types.include?(part['type'])
        end
      end

      return if part_parts.blank?

      part_parts.each_with_index.map do |part, index|
        # if the part is not the first one, check the previous part type to determine the delimiter
        delimiter = if index.positive? && part_parts[index - 1]['type'] == 'part number'
                      ', '
                    elsif index.positive? && part_parts[index - 1]['type'] == 'part name'
                      '. '
                    else
                      ''
                    end
        "#{delimiter}#{part['value']}"
      end.join
    end

    def delete_title_parts(title)
      # delete structuredValue parts from title
      if title['structuredValue'].present?
        parts_to_delete = title['structuredValue'].select do |part|
          part_types.include?(part['type'])
        end
        parts_to_delete.each do |part|
          title['structuredValue'].delete(part)
        end
      end

      return unless title['parallelValue'].present? && title['parallelValue'].first['structuredValue'].present?

      # delete title.parallelValue.structuredValue parts from title
      parts_to_delete = title['parallelValue'].first['structuredValue'].select do |part|
        part_types.include?(part['type'])
      end
      parts_to_delete.each do |part|
        title['parallelValue'].first['structuredValue'].delete(part)
      end
    end

    # QA druid for testing
    DRUIDS = [
      'druid:bc177tq6734'
    ].freeze
  end
end
