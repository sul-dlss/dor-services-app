# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps translated events from cocina to MODS XML
      class TranslatedEvent
        # @params [Nokogiri::XML::Builder] xml
        # @params [Cocina::Models::Event] event
        # @params [Integer] count
        def self.write(xml:, event:, count:)
          new(xml: xml, event: event, count: count).write
        end

        def initialize(xml:, event:, count:)
          @xml = xml
          @event = event
          @count = count
          @groups = {}
        end

        def write
          group_locations
          group_contributors

          groups.each do |script, origin|
            xml.originInfo script: script, altRepGroup: count do
              origin[:place].each do |place|
                xml.place do
                  if place[:text]
                    xml.placeTerm place[:text], type: 'text'
                  else
                    xml.placeTerm place[:code], type: 'code', authority: place[:authority]
                  end
                end
              end
              origin[:publisher].each do |publisher|
                xml.publisher publisher[:text]
              end
            end
          end
        end

        private

        attr_reader :xml, :event, :count, :groups

        def initialize_translation(key)
          groups[key] ||= { place: [], publisher: [] }
        end

        def group_locations
          Array(event.location.reverse).each do |loc|
            if loc.parallelValue
              loc.parallelValue.each do |val|
                key = val.valueLanguage.valueScript.code
                initialize_translation(key)
                groups[key][:place] << { text: val.value }
              end
            else
              initialize_translation('Latn')
              groups['Latn'][:place] << { code: loc.code, authority: loc.source.code }
            end
          end
        end

        def group_contributors
          Array(event.contributor).each do |contrib|
            next unless contrib.name.first.parallelValue

            contrib.name.first.parallelValue.each do |val|
              key = val.valueLanguage.valueScript.code
              initialize_translation(key)
              groups[key][:publisher] << { text: val.value }
            end
          end
        end
      end
    end
  end
end
