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

    # A migrator must implement a migrate method that migrates (mutates) the RepositoryObject instance.
    def migrate
      catalog_link = repository_object.head_version.identification['catalogLinks'].find do |link|
        link['catalog'] == 'folio'
      end
      return unless catalog_link

      # create the partLabel if not already populated
      if catalog_link['partLabel'].blank?
        catalog_link['partLabel'] = part_label_from_title(repository_object.head_version.description['title'].first)
        if catalog_link['partLabel'].present?
          delete_title_parts(repository_object.head_version.description['title'].first)
        end
      end
      # create the sortKey
      if catalog_link['sortKey'].blank? && repository_object.head_version.description['note'].present?
        sort_note = repository_object.head_version.description['note'].find do |note|
          note['type'] == 'date/sequential designation'
        end
        if sort_note.present?
          catalog_link['sortKey'] = sort_note['value']
          repository_object.head_version.description['note'].delete(sort_note)
        end
      end
      catalog_link['refresh'] = true
      # if the head version is open, then also migrate the last closed version
      # if repository_object.head_version.open?
      # repository_object.last_closed_version
    end

    def part_types
      ['part name', 'part number']
    end

    def part_label_from_title(title)
      # Need to check both structuredValue on title and in parallelValues
      structured_values = []
      structured_values << title['structuredValue'] if title['structuredValue'].present?
      # TODO: find out if we need to limit this to just the first structuredValue in a parallelValue
      if title['parallelValue'].present?
        title['parallelValue'].each do |parallel_value|
          structured_values << parallel_value['structuredValue'] if parallel_value['structuredValue'].present?
        end
      end

      part_parts = []
      structured_values.each do |structured_value|
        structured_value.each do |part|
          part_parts << part if part_types.include?(part['type'])
        end
      end

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
      if title['structuredValue'].present?
        title['structuredValue'].each do |structured_value|
          title['structuredValue'].delete(structured_value) if structured_value['type'] == 'part name'
          title['structuredValue'].delete(structured_value) if structured_value['type'] == 'part number'
        end
      end
      # TODO: find out if we need to limit this to just the first structuredValue in a parallelValue
      return unless title['parallelValue'].present?

      title['parallelValue'].each do |parallel_value|
        next unless parallel_value['structuredValue'].present?

        parallel_value['structuredValue'].each do |structured_value|
          parallel_value['structuredValue'].delete(structured_value) if structured_value['type'] == 'part name'
          parallel_value['structuredValue'].delete(structured_value) if structured_value['type'] == 'part number'
        end
      end
    end

    # QA druid for testing
    DRUIDS = [
      'druid:bc177tq6734'
    ].freeze
  end
end
