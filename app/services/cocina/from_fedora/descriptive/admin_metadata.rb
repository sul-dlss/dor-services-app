# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS recordInfo to cocina
      class AdminMetadata
        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          {}.tap do |admin_metadata|
            admin_metadata[:language] = build_language
            admin_metadata[:contributor] = build_contributor
            admin_metadata[:standard] = build_standard
            admin_metadata[:note] = build_note
            admin_metadata[:identifier] = build_identifier
            admin_metadata[:event] = build_event
          end.compact
        end

        private

        attr_reader :ng_xml

        def build_event
          return unless creation_event

          [{
            type: 'creation',
            date: [
              {
                value: creation_event.text,
                encoding: {
                  code: creation_event['encoding']
                }
              }
            ]
          }]
        end

        def build_identifier
          return unless identifier

          [{
            source: {
              value: identifier['source']
            },
            value: identifier.text
          }]
        end

        def build_note
          return unless record_origin

          [{
            type: 'record origin',
            value: record_origin.text
          }]
        end

        def build_standard
          return unless description_standard

          return { code: description_standard.text } unless description_standard['authority']

          {
            code: description_standard['authority'],
            uri: description_standard['valueURI'],
            source: { uri: description_standard['authorityURI'] }
          }
        end

        def build_contributor
          return unless record_content_source

          [{
            "name": [
              {
                "code": record_content_source.text,
                "uri": record_content_source['valueURI'],
                "source": {
                  code: record_content_source['authority'],
                  uri: record_content_source['authorityURI']
                }.compact
              }.compact
            ],
            "type": 'organization',
            "role": [
              {
                "value": 'original cataloging agency'
              }
            ]
          }]
        end

        def build_language
          return unless language_of_cataloging

          language = {}
          lang_text_term = language_of_cataloging.xpath('mods:languageTerm[@type="text"]', mods: DESC_METADATA_NS).first
          language[:value] = lang_text_term.text if lang_text_term
          lang_code_term = language_of_cataloging.xpath('mods:languageTerm[@type="code"]', mods: DESC_METADATA_NS).first
          language[:code] = lang_code_term.text
          language[:uri] = lang_code_term['valueURI']
          language[:source] = { code: lang_code_term['authority'], uri: lang_code_term['authorityURI'] }.compact

          script_text_term = language_of_cataloging.xpath('mods:scriptTerm[@type="text"]', mods: DESC_METADATA_NS).first
          if script_text_term
            script_code_term = language_of_cataloging.xpath('mods:scriptTerm[@type="code"]', mods: DESC_METADATA_NS).first
            language[:script] = { value: script_text_term.text, code: script_code_term.text, source: { code: script_code_term[:authority] } }
          end
          [language.compact]
        end

        def language_of_cataloging
          @language_of_cataloging ||= ng_xml.xpath('//mods:mods/mods:recordInfo/mods:languageOfCataloging', mods: DESC_METADATA_NS).first
        end

        def record_content_source
          @record_content_source ||= ng_xml.xpath('//mods:mods/mods:recordInfo/mods:recordContentSource', mods: DESC_METADATA_NS).first
        end

        def description_standard
          @description_standard ||= ng_xml.xpath('//mods:mods/mods:recordInfo/mods:descriptionStandard', mods: DESC_METADATA_NS).first
        end

        def record_origin
          @record_origin ||= ng_xml.xpath('//mods:mods/mods:recordInfo/mods:recordOrigin', mods: DESC_METADATA_NS).first
        end

        def identifier
          @identifier ||= ng_xml.xpath('//mods:mods/mods:recordInfo/mods:recordIdentifier', mods: DESC_METADATA_NS).first
        end

        def creation_event
          @creation_event ||= ng_xml.xpath('//mods:mods/mods:recordInfo/mods:recordCreationDate', mods: DESC_METADATA_NS).first
        end
      end
    end
  end
end
