# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS recordInfo to cocina
      class AdminMetadata
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder: nil)
          new(resource_element: resource_element).build
        end

        def initialize(resource_element:)
          @resource_element = resource_element
        end

        def build
          {}.tap do |admin_metadata|
            admin_metadata[:language] = build_language
            admin_metadata[:contributor] = build_contributor
            admin_metadata[:standard] = build_standard
            admin_metadata[:note] = build_note
            admin_metadata[:identifier] = build_identifier
            admin_metadata[:event] = build_events
          end.compact
        end

        private

        attr_reader :resource_element

        def build_events
          events = []
          events << build_event_for(creation_event, 'creation') if creation_event
          events << build_event_for(modification_event, 'modification') if modification_event

          return nil if events.empty?

          events
        end

        def build_event_for(node, type)
          event_code = node['encoding']
          encoding = { code: event_code } if event_code
          {
            type: type,
            date: [
              {
                value: node.text,
                encoding: encoding
              }.compact
            ]
          }
        end

        def build_identifier
          return unless identifier

          [{
            value: identifier.text
          }.tap do |model|
            model[:source] = { value: identifier['source'] } if identifier['source']
          end]
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
          if lang_code_term
            language[:code] = lang_code_term.text
            language[:uri] = lang_code_term['valueURI']
            language[:source] = { code: lang_code_term['authority'], uri: lang_code_term['authorityURI'] }.compact
          end

          script_text_term = language_of_cataloging.xpath('mods:scriptTerm[@type="text"]', mods: DESC_METADATA_NS).first
          if script_text_term
            script_code_term = language_of_cataloging.xpath('mods:scriptTerm[@type="code"]', mods: DESC_METADATA_NS).first
            script_term_source = { code: script_code_term['authority'] } if script_code_term['authority']
            language[:script] = { value: script_text_term.text, code: script_code_term.text, source: script_term_source }.compact
          end
          language[:status] = language_of_cataloging[:usage]

          [language.compact]
        end

        def language_of_cataloging
          @language_of_cataloging ||= resource_element.xpath('mods:recordInfo/mods:languageOfCataloging', mods: DESC_METADATA_NS).first
        end

        def record_content_source
          @record_content_source ||= resource_element.xpath('mods:recordInfo/mods:recordContentSource', mods: DESC_METADATA_NS).first
        end

        def description_standard
          @description_standard ||= resource_element.xpath('mods:recordInfo/mods:descriptionStandard', mods: DESC_METADATA_NS).first
        end

        def record_origin
          @record_origin ||= resource_element.xpath('mods:recordInfo/mods:recordOrigin', mods: DESC_METADATA_NS).first
        end

        def identifier
          @identifier ||= resource_element.xpath('mods:recordInfo/mods:recordIdentifier', mods: DESC_METADATA_NS).first
        end

        def creation_event
          @creation_event ||= resource_element.xpath('mods:recordInfo/mods:recordCreationDate', mods: DESC_METADATA_NS).first
        end

        def modification_event
          @modification_event ||= resource_element.xpath('mods:recordInfo/mods:recordChangeDate', mods: DESC_METADATA_NS).first
        end
      end
    end
  end
end
