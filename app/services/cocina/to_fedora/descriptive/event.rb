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
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::Event>] events
        def self.write(xml:, events:)
          new(xml: xml, events: events).write
        end

        def initialize(xml:, events:)
          @xml = xml
          @events = events
        end

        def write
          events.each_with_index do |event, _alt_rep_group|
            write_basic(event)
          end
        end

        private

        attr_reader :xml, :events

        def write_basic(event)
          xml.originInfo do
            Array(event.date).each do |date|
              basic_date(date, event.type)
            end
            Array(event.location).each do |loc|
              location(loc)
            end
            Array(event.contributor).each do |contrib|
              contributor(contrib)
            end
          end
        end

        def contributor(contributor)
          attributes = {}
          name = contributor.name.first
          if name.valueLanguage
            attributes[:lang] = name.valueLanguage.code
            attributes[:script] = name.valueLanguage.valueScript.code
            attributes[:transliteration] = name.standard.value
          end
          xml.send(contributor.role.first.value, name.value, attributes)
        end

        def location(location)
          if location.code
            xml.place do
              xml.placeTerm location.value, type: 'text', authority: location.source.code, authorityURI: location.source.uri, valueURI: location.uri if location.value
              attributes = { type: 'code', authority: location.source.code }
              if location.uri
                attributes[:valueURI] = location.uri
                attributes[:authorityURI] = location.source.uri
              end
              xml.placeTerm location.code, attributes
            end
          elsif location.value
            location_text_value(location)
          end
        end

        def location_text_value(location)
          attributes = {}
          if location.uri
            attributes[:authority] = location.source.code
            attributes[:authorityURI] = location.source.uri
            attributes[:valueURI] = location.uri
          end
          xml.place attributes do
            xml.placeTerm location.value, type: 'text'
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
          attributes[:type] = date.note.find { |note| note.type == 'date type' }.value if tag == :dateOther

          xml.public_send(tag, value, attributes)
        end

        def date_range(dates, event_type)
          dates.each do |date|
            date_tag(date, event_type, point: date.type)
          end
        end
      end
    end
  end
end
