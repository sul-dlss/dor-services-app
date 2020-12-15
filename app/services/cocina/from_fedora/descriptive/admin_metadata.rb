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
          return nil if record_info.nil?

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
          identifiers = record_identifiers.map { |identifier| IdentifierBuilder.build_from_record_identifier(identifier_element: identifier) }

          return nil if identifiers.empty?

          identifiers
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
            uri: ValueURI.sniff(description_standard['valueURI']),
            source: { uri: description_standard['authorityURI'] }
          }
        end

        def build_contributor
          return unless record_content_source

          [{
            name: [
              {
                code: record_content_source.text,
                uri: ValueURI.sniff(record_content_source['valueURI'])
              }.tap do |name_attrs|
                source = {
                  code: record_content_source['authority'],
                  uri: record_content_source['authorityURI']
                }.compact
                name_attrs[:source] = source unless source.empty?
              end.compact
            ],
            type: 'organization',
            role: [
              {
                value: 'original cataloging agency'
              }
            ]
          }]
        end

        def build_language
          return if language_of_cataloging.empty?

          language_of_cataloging.map { |lang_node| Cocina::FromFedora::Descriptive::LanguageTerm.build(language_element: lang_node) }
        end

        def record_info
          @record_info ||= resource_element.xpath('mods:recordInfo[1]', mods: DESC_METADATA_NS).first
        end

        def language_of_cataloging
          @language_of_cataloging ||= record_info.xpath('mods:languageOfCataloging', mods: DESC_METADATA_NS)
        end

        def record_content_source
          @record_content_source ||= record_info.xpath('mods:recordContentSource', mods: DESC_METADATA_NS).first
        end

        def description_standard
          @description_standard ||= record_info.xpath('mods:descriptionStandard', mods: DESC_METADATA_NS).first
        end

        def record_origin
          @record_origin ||= record_info.xpath('mods:recordOrigin', mods: DESC_METADATA_NS).first
        end

        def creation_event
          @creation_event ||= record_info.xpath('mods:recordCreationDate', mods: DESC_METADATA_NS).first
        end

        def modification_event
          @modification_event ||= record_info.xpath('mods:recordChangeDate', mods: DESC_METADATA_NS).first
        end

        def record_identifiers
          @record_identifiers ||= record_info.xpath('mods:recordIdentifier', mods: DESC_METADATA_NS)
        end
      end
    end
  end
end
