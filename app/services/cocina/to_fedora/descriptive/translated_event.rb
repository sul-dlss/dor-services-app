# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps translated events from cocina to MODS XML
      class TranslatedEvent
        # @params [Nokogiri::XML::Builder] xml
        # @params [Cocina::Models::Event] event
        # @params [String] alt_rep_group
        # @params [String] event_type - see Cocina::ToFedora::Descriptive::Event::EVENT_TYPE
        def self.write(xml:, event:, alt_rep_group:, event_type:)
          new(xml: xml, event: event, alt_rep_group: alt_rep_group, event_type: event_type).write
        end

        def initialize(xml:, event:, alt_rep_group:, event_type:)
          @xml = xml
          @event = event
          @alt_rep_group = alt_rep_group
          @event_type = event_type
          @groups = {}
        end

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/BlockLength
        def write
          group_locations
          group_contributors
          group_dates

          groups.each do |script, origin|
            attributes = {
              script: script,
              altRepGroup: alt_rep_group,
              eventType: event_type
            }
            attributes[:lang] = origin[:lang_code] if origin[:lang_code].present?

            xml.originInfo attributes do
              origin[:place].each do |place|
                xml.place do
                  if place[:text]
                    xml.placeTerm place[:text], place[:attributes].merge(type: 'text')
                  else
                    xml.placeTerm place[:code], type: 'code', authority: place[:authority]
                  end
                end
              end
              origin[:publisher].each do |publisher|
                xml.publisher publisher[:text]
              end
              origin[:dateIssued].each do |date_issued|
                xml.dateIssued date_issued[:text], date_issued[:attributes]
              end
              origin[:dateCreated].each do |date_created|
                xml.dateCreated date_created[:text], date_created[:attributes]
              end
              write_notes if script == 'Latn'
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/BlockLength

        private

        attr_reader :xml, :event, :alt_rep_group, :event_type, :groups

        def initialize_translation(key)
          groups[key] ||= { place: [], publisher: [], dateIssued: [], dateCreated: [], lang_code: [] }
        end

        def group_locations
          Array(event.location).each do |loc|
            if loc.parallelValue
              loc.parallelValue.each do |desc_value|
                key = desc_value.valueLanguage.valueScript.code
                initialize_translation(key)

                groups[key][:lang_code] = desc_value.valueLanguage.code if desc_value.valueLanguage&.code
                groups[key][:place] << group_location_value(desc_value)
              end
            else
              initialize_translation('Latn')
              groups['Latn'][:place] << { code: loc.code, authority: loc.source.code }
            end
          end
        end

        def group_location_value(desc_value)
          attributes = {}
          attributes[:valueURI] = desc_value.uri if desc_value.uri
          attributes[:authorityURI] = desc_value.source.uri if desc_value.source&.uri

          { text: desc_value.value, attributes: attributes }
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

        def group_dates
          Array(event.date).each do |date|
            tag = Cocina::ToFedora::Descriptive::Event::TAG_NAME.fetch(event.type, :dateOther)
            if date.parallelValue
              date.parallelValue.each do |val|
                key = val.valueLanguage&.valueScript&.code || 'Latn'
                initialize_translation(key)
                groups[key][tag] << group_date_value(val, tag)
              end
            else
              initialize_translation('Latn')
              groups['Latn'][tag] << group_date_value(date, tag)
            end
          end
        end

        def group_date_value(desc_value, tag)
          attributes = {}
          attributes[:encoding] = desc_value.encoding.code if desc_value.encoding
          attributes[:qualifier] = desc_value.qualifier if desc_value.qualifier
          attributes[:keyDate] = 'yes' if desc_value.status == 'primary'
          attributes[:type] = desc_value.note.find { |note| note.type == 'date type' }.value if tag == :dateOther && desc_value.note

          { text: desc_value.value, attributes: attributes }
        end

        def write_notes
          Array(event.note).each do |note|
            xml.issuance(note.value) if note.type == 'issuance'
          end
        end
      end
    end
  end
end
