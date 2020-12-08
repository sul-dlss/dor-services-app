# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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
          group_edition_notes
          normalize_groups

          groups.each do |script, origin|
            attributes = {
              script: script,
              altRepGroup: alt_rep_group,
              eventType: event_type
            }
            attributes[:lang] = origin[:lang_code] if origin[:lang_code].present?
            attributes.delete(:script) if attributes[:script].blank?

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
              origin[:edition].each do |edition|
                xml.edition edition[:text]
              end
              write_notes if ['Latn', ''].include?(script)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/BlockLength

        private

        attr_reader :xml, :event, :alt_rep_group, :event_type, :groups

        def initialize_translation(key)
          groups[key] ||= { place: [], publisher: [], dateIssued: [], dateCreated: [], edition: [], lang_code: [] }
        end

        # to be called after the group keys and values have been set up
        #  if there is a key of '', those values should be merged to Latn script or eng language
        # see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#1202
        # rubocop:disable Metrics/AbcSize
        def normalize_groups
          # we must have '' and Latn groups to do anything useful
          #  unless we want to look through all the groups for lang_code 'eng' and muck about
          return if !groups.key?('') || !groups.key?('Latn')

          groups['Latn'][:place] += groups[''][:place]
          groups['Latn'][:publisher] += groups[''][:publisher]
          groups['Latn'][:dateIssued] += groups[''][:dateIssued]
          groups['Latn'][:dateCreated] += groups[''][:dateCreated]
          groups['Latn'][:edition] += groups[''][:edition]
          groups['Latn'][:lang_code] ||= groups[''][:lang_code]
          groups.delete('')
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        def group_locations
          Array(event.location).each do |loc|
            if loc.parallelValue
              loc.parallelValue.each do |desc_value|
                if desc_value.valueLanguage.blank?
                  initialize_translation('')
                  groups[''][:place] << { code: desc_value&.code, authority: desc_value&.source&.code }
                else
                  key = desc_value.valueLanguage.valueScript.code
                  initialize_translation(key)

                  groups[key][:lang_code] = desc_value.valueLanguage.code if desc_value.valueLanguage&.code
                  groups[key][:place] << group_location_value(desc_value)
                end
              end
            else
              initialize_translation('')
              groups[''][:place] << { code: loc.code, authority: loc.source.code }
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

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
              key = val.valueLanguage.blank? ? '' : val.valueLanguage.valueScript.code
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
                key = val.valueLanguage&.valueScript&.code || ''
                initialize_translation(key)
                groups[key][tag] << group_date_value(val, tag)
              end
            else
              initialize_translation('')
              groups[''][tag] << group_date_value(date, tag)
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

        def group_edition_notes
          Array(event.note).each do |note_desc_value|
            next if note_desc_value.type != 'edition'

            if note_desc_value.parallelValue
              note_desc_value.parallelValue.each do |desc_value|
                key = desc_value.valueLanguage&.valueScript&.code || ''
                initialize_translation(key)

                groups[key][:edition] << { text: desc_value.value }
                groups[key][:lang_code] = desc_value.valueLanguage.code if desc_value.valueLanguage&.code
              end
            else
              initialize_translation('')
              groups[''][:edition] << { text: note_desc_value.value }
            end
          end
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
# rubocop:enable Metrics/ClassLength
