# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps events from cocina to MODS XML
      class Event
        TAG_NAME = {
          'creation' => :dateCreated,
          'publication' => :dateIssued,
          'copyright' => :copyrightDate
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
            value = date.value
            attributes = {}
            attributes[:encoding] = date.encoding.code if date.encoding
            xml.public_send(TAG_NAME.fetch(event.type), value, attributes)
          end
        end
      end
    end
  end
end
