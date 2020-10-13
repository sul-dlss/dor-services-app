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
            date = event.date.first
            if date.structuredValue
              date_range(date.structuredValue, event.type)
            else
              date_tag(date, event.type)
            end
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
