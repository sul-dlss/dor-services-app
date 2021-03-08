# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps events from cocina to MODS XML
      class Event
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
            if event.parallelEvent.present?
              write_parallel(event, id_generator.next_altrepgroup)
            else
              write_basic(event, event.type)
            end
          end
        end

        private

        attr_reader :xml, :events, :id_generator

        def write_basic(event, event_type)
          names = Array(event.contributor).map { |contributor| contributor.name.first }
          attributes = {
            displayLabel: event.displayLabel,
            eventType: event_type,
            script: event.valueLanguage&.valueScript&.code,
            lang: event.valueLanguage&.code
          }.compact

          write_event(event.type, event.date, event.location, names, event.note, attributes)
        end

        def write_parallel(event, alt_rep_group)
          event.parallelEvent.each do |parallel_event|
            attributes = {}.tap do |attrs|
              attrs[:script] = parallel_event.valueLanguage&.valueScript&.code
              attrs[:lang] = parallel_event.valueLanguage&.code
              attrs[:altRepGroup] = alt_rep_group
              attrs[:eventType] = event.type || parallel_event.type
              attrs[:displayLabel] = event.displayLabel || parallel_event.displayLabel
            end.compact

            names = Array(parallel_event.contributor).map(&:name).flatten
            write_event(parallel_event.type,
                        parallel_event.date,
                        parallel_event.location,
                        names,
                        parallel_event.note,
                        attributes)
          end
        end

        # rubocop:disable Metrics/ParameterLists
        def write_event(cocina_event_type, dates, locations, names, notes, attributes, is_parallel: false)
          return if dates.blank? && locations.blank? && names.blank? && notes.blank?

          xml.originInfo attributes do
            Array(dates).each do |date|
              write_basic_date(date, cocina_event_type)
            end
            Array(locations).each do |loc|
              write_location(loc)
            end
            Array(names).each do |name|
              xml.publisher name.value, name_attributes(name)
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
          xml.send(note_tag_for(note), note.value, attributes)
        end

        def note_tag_for(note)
          return 'copyrightDate' if note.type == 'copyright statement'
          return note.type if note.type

          'edition'
        end

        def write_location(location)
          place_attrs = {}.tap do |attrs|
            attrs[:supplied] = 'yes' if location.type == 'supplied'
          end
          xml.place place_attrs do
            placeterm_attrs = {}
            placeterm_attrs[:authority] = location.source.code if location.source&.code
            placeterm_attrs[:authorityURI] = location.source.uri if location.source&.uri
            placeterm_attrs[:valueURI] = location.uri if location.uri

            placeterm_text_attrs = placeterm_attrs.merge({ type: 'text' })
            xml.placeTerm location.value, placeterm_text_attrs if location.value

            placeterm_code_attrs = placeterm_attrs.merge({ type: 'code' })
            xml.placeTerm location.code, placeterm_code_attrs if location.code
          end
        end

        def write_basic_date(date, cocina_event_type)
          if date.structuredValue
            structured_val_attribs = {
              encoding: date.encoding,
              qualifier: date.qualifier,
              type: date.type
            }
            date_type = cocina_event_type
            date_type = date.type if date.type.present?
            date_range(date.structuredValue, date_type, structured_val_attribs)
          else
            write_date_element(date, cocina_event_type)
          end
        end

        # @param [Hash] structured_val_attribs - populated when structuredValue parent has attributes for individual date elements
        def write_date_element(date, cocina_event_type, structured_val_attribs = {})
          return write_dates_for_edtf_range(date, cocina_event_type) if edtf_range?(date)

          value = date.value
          element_name = date_element_name(date, cocina_event_type, structured_val_attribs[:type])
          attributes = {}.tap do |attrs|
            attrs[:encoding] = date.encoding&.code || structured_val_attribs[:encoding]&.code
            attrs[:qualifier] = date.qualifier || structured_val_attribs[:qualifier]
            attrs[:keyDate] = key_date_attr(date)
            attrs[:type] = date_type_attr(date, element_name)
            attrs[:calendar] = calendar_attr(date)
            attrs[:point] = date.type if %w[start end].include?(date.type)
          end.compact
          xml.public_send(element_name, value, attributes)
        end

        def date_element_name(date, cocina_event_type, structured_val_type)
          el_name = Cocina::FromFedora::Descriptive::Event::DATE_ELEMENTS_2_TYPE.key(structured_val_type)
          return el_name if el_name.present?

          el_name = Cocina::FromFedora::Descriptive::Event::DATE_ELEMENTS_2_TYPE.key(date.type)
          return el_name if el_name.present?

          # the date type overrides the eventType for choosing date flavor, even if it ends up with dateOther
          return 'dateOther' if date.type.present?

          if cocina_event_type.present?
            el_name = Cocina::FromFedora::Descriptive::Event::DATE_ELEMENTS_2_TYPE.key(cocina_event_type)
            return el_name if el_name.present?
          end

          'dateOther'
        end

        # FIXME: to be implemented: if we only have end then it can be keyDate, otherwise it should be start only
        # if there is a date range, then type can be 'start' and 'end'
        def key_date_attr(cocina_date)
          'yes' if cocina_date.status == 'primary' # && cocina_date.type != 'end'
        end

        # MODS only allows a type attr on dateOther; no other date flavors
        #   FIXME: the following comment may become untrue ...
        #   edtf dates will have type 'start' and/or 'end';  this type should not be used
        def date_type_attr(cocina_date, date_element_name)
          return unless date_element_name == 'dateOther'

          cocina_date.type if cocina_date.type.present? && ['start', 'end'].exclude?(cocina_date.type)
        end

        def calendar_attr(cocina_date)
          return if cocina_date.note.blank?

          cocina_date.note.each do |note|
            return note.value if note.type == 'calendar'
          end
        end

        def edtf_range?(date)
          date.encoding&.code == 'edtf' && date.value.include?('/')
        end

        # @param [String] date An EDTF range
        # FIXME: to be implemented: model edtf date range in cocina like other date ranges;
        #   put the slash back in when mapping back to MODS
        def write_dates_for_edtf_range(date, cocina_event_type)
          start_date, end_date = date.value.split('/')
          write_date_element(date.new(value: start_date, type: 'start'), cocina_event_type)
          write_date_element(date.new(value: end_date, type: 'end'), cocina_event_type)
        end

        def date_range(dates, cocina_event_type, structured_val_attribs)
          dates.each do |date|
            write_date_element(date, cocina_event_type, structured_val_attribs)
          end
        end

        def name_attributes(cocina_name)
          {
            lang: cocina_name&.valueLanguage&.code,
            script: cocina_name&.valueLanguage&.valueScript&.code,
            transliteration: cocina_name&.standard&.value
          }.compact
        end
      end
    end
  end
end
