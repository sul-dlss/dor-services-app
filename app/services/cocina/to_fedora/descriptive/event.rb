# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps events from cocina to MODS XML
      class Event
        TAG_NAME = {
          'production' => :dateCreated,
          'publication' => :dateIssued,
          'copyright notice' => :copyrightDate,
          'capture' => :dateCaptured
        }.freeze

        EVENT_TYPE = {
          'capture' => 'capture',
          'copyright' => 'copyright notice',
          'creation' => 'production',
          'distribution' => 'distribution',
          'manufacture' => 'manufacture',
          'publication' => 'publication',
          'acquisition' => 'acquisition',
          'development' => 'development'
        }.freeze

        GroupedParallelValues = Struct.new(:locations, :names, :dates, :notes, :value_language)

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::Event>] events
        # @params [IdGenerator] id_generator
        def self.write(xml:, events:, id_generator:)
          new(xml: xml, events: events, id_generator: id_generator).write
        end

        def initialize(xml:, events:, id_generator:)
          @xml = xml
          @events = events
          @id_generator = id_generator
        end

        def write
          Array(events).each do |event|
            event_type = EVENT_TYPE.fetch(event.type) if event.type
            if translated?(event)
              write_translated(event, event_type, id_generator.next_altrepgroup)
            else
              write_basic(event, event_type)
            end
          end
        end

        private

        attr_reader :xml, :events, :id_generator

        def translated?(event)
          Array(event.location).any?(&:parallelValue) ||
            Array(event.contributor).flat_map(&:name).any?(&:parallelValue) ||
            Array(event.note).any?(&:parallelValue) ||
            Array(event.date).any?(&:parallelValue)
        end

        def write_basic(event, event_type)
          attributes = {
            displayLabel: event.displayLabel,
            eventType: event_type
          }.compact

          names = Array(event.contributor).map { |contributor| contributor.name.first }

          write_event(event_type, event.date, event.location, names, event.note, attributes)
        end

        def write_translated(event, event_type, alt_rep_group)
          grouped_parallel_values = grouped_parallel_values_for(event)
          add_other_descriptive_values_to(grouped_parallel_values, event)

          grouped_parallel_values.each do |grouped_parallel_value|
            attributes = {
              script: grouped_parallel_value.value_language&.valueScript&.code,
              lang: grouped_parallel_value.value_language&.code,
              altRepGroup: alt_rep_group,
              eventType: event_type
            }.compact

            write_event(event_type,
                        grouped_parallel_value.dates,
                        grouped_parallel_value.locations,
                        grouped_parallel_value.names,
                        grouped_parallel_value.notes,
                        attributes,
                        is_parallel: true)
          end
        end

        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/AbcSize
        def grouped_parallel_values_for(event)
          # This assumes that parallelValues all share the same order. Thus, this depends on order rather than matching lang/script.
          # Note that since not all parallelValues even have lang/script this is a use simplification.

          parallel_locations = Array(event.location).select(&:parallelValue)
          parallel_names = Array(event.contributor).map do |contributor|
            contributor.name.select(&:parallelValue)
          end.flatten.compact
          parallel_dates = Array(event.date).select(&:parallelValue)
          parallel_edition_notes = Array(event.note).select { |note| note.type == 'edition' && note.parallelValue }

          parallels_size = [parallel_locations.size, parallel_names.size, parallel_dates.size, parallel_edition_notes.size].max

          grouped_parallel_values = []
          (0..parallels_size - 1).each do |parallels_index|
            parallel_location = parallel_locations[parallels_index]
            parallel_name = parallel_names[parallels_index]
            parallel_date = parallel_dates[parallels_index]
            parallel_edition_note = parallel_edition_notes[parallels_index]
            parallel_size = parallel_size_for([parallel_location, parallel_name, parallel_date, parallel_edition_note])
            (0..parallel_size - 1).each do |parallel_value_index|
              parallel_location_value = parallel_location&.parallelValue&.slice(parallel_value_index)
              parallel_name_value = parallel_name&.parallelValue&.slice(parallel_value_index)
              parallel_date_value = parallel_date&.parallelValue&.slice(parallel_value_index)
              parallel_edition_note_value = parallel_edition_note&.parallelValue&.slice(parallel_value_index)
              value_language = value_language_for([parallel_location_value, parallel_name_value, parallel_date_value, parallel_edition_note_value])
              grouped_parallel_values << GroupedParallelValues.new(
                Array(parallel_location_value),
                Array(parallel_name_value),
                Array(parallel_date_value),
                Array(parallel_edition_note_value),
                value_language
              )
            end
          end
          grouped_parallel_values
        end

        def add_other_descriptive_values_to(grouped_parallel_values, event)
          # Dates, names, location, editions that are not parallel are merged into the parallel.
          # Any where lang=eng or script=Ltn, otherwise all
          default_grouped_parallel_values = grouped_parallel_values.select do |grouped_parallel_value|
            grouped_parallel_value.value_language&.code == 'eng' || grouped_parallel_value.value_language&.valueScript&.code == 'Latn'
          end.presence || grouped_parallel_values

          default_grouped_parallel_values.each do |grouped_parallel_value|
            other_locations = Array(event.location).reject(&:parallelValue)
            grouped_parallel_value.locations.concat(other_locations)
            other_dates = Array(event.date).reject(&:parallelValue)
            grouped_parallel_value.dates.concat(other_dates)
            other_notes = Array(event.note).reject { |note| note.type == 'edition' && note.parallelValue }
            grouped_parallel_value.notes.concat(other_notes)
            other_parallel_names = Array(event.contributor).map do |contributor|
              Array(contributor.name).reject(&:parallelValue)
            end.flatten.compact
            grouped_parallel_value.names.concat(other_parallel_names)
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/AbcSize

        def parallel_size_for(parallels)
          parallels.map { |parallel| parallel&.parallelValue&.size }.compact.max
        end

        def value_language_for(parallel_values)
          parallel_values.find { |descriptive_value| descriptive_value&.valueLanguage }&.valueLanguage
        end

        # rubocop:disable Metrics/ParameterLists
        def write_event(event_type, dates, locations, names, notes, attributes, is_parallel: false)
          xml.originInfo attributes do
            Array(dates).each do |date|
              write_basic_date(date, event_type)
            end
            Array(locations).each do |loc|
              write_location(loc)
            end
            Array(names).each do |name|
              write_name(name, is_parallel: is_parallel)
            end
            Array(notes).each do |note|
              write_note(note)
            end
          end
        end
        # rubocop:enable Metrics/ParameterLists

        def write_note(note)
          attributes = {}
          attributes[:authority] = note.source.code if note&.source&.code
          xml.send(note.type || 'edition', note.value, attributes)
        end

        def write_name(name, is_parallel: false)
          attributes = if is_parallel
                         {}
                       else
                         {
                           lang: name.valueLanguage&.code,
                           script: name.valueLanguage&.valueScript&.code,
                           transliteration: name.standard&.value

                         }.compact
                       end

          xml.publisher(name.value, attributes)
        end

        def write_location(location)
          xml.place do
            placeterm_attrs = { type: 'text' }
            placeterm_attrs[:authority] = location.source.code if location.source&.code
            placeterm_attrs[:authorityURI] = location.source.uri if location.source&.uri
            placeterm_attrs[:valueURI] = location.uri if location.uri

            placeterm_text_attrs = placeterm_attrs.merge({ type: 'text' })
            xml.placeTerm location.value, placeterm_text_attrs if location.value

            placeterm_code_attrs = placeterm_attrs.merge({ type: 'code' })
            xml.placeTerm location.code, placeterm_code_attrs if location.code
          end
        end

        def write_basic_date(date, event_type)
          if date.structuredValue
            date_range(date.structuredValue, event_type)
          else
            date_tag(date, event_type)
          end
        end

        def date_tag(date, event_type)
          value = date.value
          tag = TAG_NAME.fetch(event_type, :dateOther)
          attributes = {
            encoding: date.encoding&.code,
            qualifier: date.qualifier
          }.tap do |attrs|
            attrs[:keyDate] = 'yes' if date.status == 'primary'
            attrs[:type] = date.note.find { |note| note.type == 'date type' }.value if tag == :dateOther && date.note
            attrs[:type] = 'developed' if event_type == 'development'
            attrs[:point] = date.type if %w[start end].include?(date.type)
          end.compact
          xml.public_send(tag, value, attributes)
        end

        def date_range(dates, event_type)
          dates.each do |date|
            date_tag(date, event_type)
          end
        end

        MARC_RELATOR_PIECE = 'id.loc.gov/vocabulary/relators'

        # prefer marcrelator publisher role
        def contributor_role_publisher?(contributor)
          return true if contributor.role.any? { |role| role.value.match?(/publisher/i) && role_is_marcrelator?(role) }

          contributor.role.any? { |role| role.value&.match?(/publisher/i) }
        end

        def role_is_marcrelator?(role)
          role.source&.code == 'marcrelator' ||
            role.source&.uri&.include?(MARC_RELATOR_PIECE) ||
            role.uri&.include?(MARC_RELATOR_PIECE)
        end
      end
    end
  end
end
