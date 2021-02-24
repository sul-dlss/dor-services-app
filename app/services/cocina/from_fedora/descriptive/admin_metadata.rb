# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS recordInfo to cocina
      class AdminMetadata
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:, purl: nil)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @descriptive_builder = descriptive_builder
          @notifier = descriptive_builder.notifier
        end

        def build
          return nil if record_info.nil?

          {}.tap do |admin_metadata|
            admin_metadata[:language] = build_language
            admin_metadata[:contributor] = build_contributor
            admin_metadata[:metadataStandard] = build_standard
            admin_metadata[:note] = build_note
            admin_metadata[:identifier] = build_identifier
            admin_metadata[:event] = build_events
          end.compact
        end

        private

        attr_reader :resource_element, :notifier, :descriptive_builder

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
          notes = []
          record_origins.each do |record_origin|
            notes << {
              type: 'record origin',
              value: record_origin.text
            }
          end
          if record_info_note
            notes << {
              valueAt: record_info_note['xlink:href']
            }
          end
          notes.presence
        end

        def build_standard
          return unless description_standards

          description_standards.map do |description_standard|
            source = {
              uri: Authority.normalize_uri(description_standard['authorityURI']),
              code: description_standard['authority']
            }.compact
            {
              uri: ValueURI.sniff(description_standard['valueURI'], notifier),
              source: source.presence
            }.tap do |attrs|
              if description_standard.text.present?
                if description_standard.text == description_standard.text.downcase
                  attrs[:code] = description_standard.text
                else
                  attrs[:value] = description_standard.text
                end
              end
            end.compact
          end.presence
        end

        def build_contributor
          record_content_sources.map do |record_content_source|
            if record_content_source['authority'] == 'marcorg'
              build_contributor_code(record_content_source)
            else
              build_contributor_value(record_content_source)
            end
          end.presence
        end

        def build_contributor_value(record_content_source)
          {
            name: [
              {
                value: record_content_source.text,
                uri: ValueURI.sniff(record_content_source['valueURI'], notifier),
                source: source_for(record_content_source)

              }.compact
            ]
          }
        end

        def build_contributor_code(record_content_source)
          {
            name: [
              {
                code: record_content_source.text,
                uri: ValueURI.sniff(record_content_source['valueURI'], notifier),
                source: source_for(record_content_source)
              }.compact
            ],
            type: 'organization',
            role: [
              {
                value: 'original cataloging agency'
              }
            ]
          }
        end

        def source_for(record_content_source)
          {
            code: record_content_source['authority'],
            uri: record_content_source['authorityURI']
          }.compact.presence
        end

        def build_language
          return if language_of_cataloging.empty?

          language_of_cataloging.map do |lang_node|
            Cocina::FromFedora::Descriptive::LanguageTerm.build(
              language_element: lang_node,
              notifier: notifier
            )
          end
        end

        def record_info
          @record_info ||= resource_element.xpath('mods:recordInfo[1]', mods: DESC_METADATA_NS).first
        end

        def language_of_cataloging
          @language_of_cataloging ||= record_info.xpath('mods:languageOfCataloging', mods: DESC_METADATA_NS)
        end

        def record_content_sources
          @record_content_sources ||= record_info.xpath('mods:recordContentSource', mods: DESC_METADATA_NS)
        end

        def description_standards
          @description_standards ||= record_info.xpath('mods:descriptionStandard', mods: DESC_METADATA_NS)
        end

        def record_origins
          @record_origins ||= record_info.xpath('mods:recordOrigin', mods: DESC_METADATA_NS)
        end

        def record_info_note
          @record_info_note ||= record_info.xpath('mods:recordInfoNote[@xlink:href]', mods: DESC_METADATA_NS, xlink: XLINK_NS).first
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
