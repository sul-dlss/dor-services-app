# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps events from cocina to MODS XML
      class Event
        TAG_NAME = {
          'creation' => :dateCreated,
          'publication' => :dateIssued,
          'copyright' => :copyrightDate,
          'capture' => :dateCaptured
        }.freeze

        EVENT_TYPE = {
          'capture' => 'capture',
          'copyright' => 'copyright notice',
          'creation' => 'production',
          'publication' => 'publication',
          'acquisition' => 'acquisition'
        }.freeze

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
            attributes = {}
            attributes[:eventType] = event_type if event_type

            if translated?(event)
              TranslatedEvent.write(xml: xml, event: event, alt_rep_group: id_generator.next_altrepgroup, event_type: event_type)
            else
              write_basic(event, attributes)
            end
          end
        end

        private

        attr_reader :xml, :events, :id_generator

        def translated?(event)
          Array(event.location).any?(&:parallelValue) &&
            Array(event.contributor).flat_map(&:name).all?(&:parallelValue) ||
            Array(event.note).any?(&:parallelValue)
        end

        def write_basic(event, attributes)
          attributes[:displayLabel] = event.displayLabel if event.displayLabel
          xml.originInfo attributes do
            Array(event.date).each do |date|
              basic_date(date, event.type)
            end
            Array(event.location).each do |loc|
              location(loc)
            end
            Array(event.contributor).each do |contrib|
              contributor(contrib)
            end
            Array(event.note).each do |note|
              note(note)
            end
          end
        end

        def note(note)
          attributes = {}
          attributes[:authority] = note.source.code if note&.source&.code
          xml.send(note.type, note.value, attributes)
        end

        # the only contributors legal for MODS are ones with role publisher
        def contributor(contributor)
          return unless contributor_role_publisher?(contributor)

          attributes = {}
          name = contributor.name.first
          if name.valueLanguage
            attributes[:lang] = name.valueLanguage.code
            attributes[:script] = name.valueLanguage.valueScript.code
            attributes[:transliteration] = name.standard.value if name.standard
          end

          xml.publisher(name.value, attributes)
        end

        def location(location)
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

        def basic_date(date, event_type)
          if date.structuredValue
            date_range(date.structuredValue, event_type)
          else
            date_tag(date, event_type)
          end
        end

        def date_tag(date, event_type, attributes = {})
          value = date.value
          tag = TAG_NAME.fetch(event_type, :dateOther)
          attributes[:encoding] = date.encoding.code if date.encoding
          attributes[:qualifier] = date.qualifier if date.qualifier
          attributes[:keyDate] = 'yes' if date.status == 'primary'
          attributes[:type] = date.note.find { |note| note.type == 'date type' }.value if tag == :dateOther && date.note

          xml.public_send(tag, value, attributes)
        end

        def date_range(dates, event_type)
          dates.each do |date|
            date_tag(date, event_type, point: date.type)
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
