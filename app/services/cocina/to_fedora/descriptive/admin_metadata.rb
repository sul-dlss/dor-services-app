# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps adminMetadata from cocina to MODS XML recordInfo
      class AdminMetadata
        # @params [Nokogiri::XML::Builder] xml
        # @params [Cocina::Models::DescriptiveAdminMetadata] admin_metadata
        def self.write(xml:, admin_metadata:)
          new(xml: xml, admin_metadata: admin_metadata).write
        end

        def initialize(xml:, admin_metadata:)
          @xml = xml
          @admin_metadata = admin_metadata
        end

        def write
          return unless admin_metadata

          xml.recordInfo do
            build_language
            build_content_source
            build_description_standard
            build_record_origin
            build_event
            build_identifier
          end
        end

        private

        attr_reader :xml, :admin_metadata

        def build_record_origin
          xml.recordOrigin admin_metadata.note&.find { |note| note.type == 'record origin' }&.value if admin_metadata.note.present?
        end

        def build_content_source
          Array(admin_metadata.contributor).each do |contributor|
            source = contributor.name.first
            xml.recordContentSource source.code || source.value, with_uri_info(source)
          end
        end

        def build_description_standard
          return if admin_metadata.metadataStandard.blank?

          admin_metadata.metadataStandard.each do |standard|
            xml.descriptionStandard standard.code || standard.value, with_uri_info(standard)
          end
        end

        def build_event
          build_event_for('creation', 'recordCreationDate')
          build_event_for('modification', 'recordChangeDate')
        end

        def build_event_for(type, tag)
          Array(admin_metadata.event).select { |note| note.type == type }.each do |event|
            event.date.each do |date|
              attributes = {}.tap do |attrs|
                attrs[:encoding] = date.encoding&.code
              end.compact

              xml.public_send(tag, date.value, attributes)
            end
          end
        end

        def build_identifier
          Array(admin_metadata.identifier).each do |identifier|
            id_attributes = {
              displayLabel: identifier.displayLabel,
              source: identifier.uri ? 'uri' : FromFedora::Descriptive::IdentifierType.mods_type_for_cocina_type(identifier.type)
            }.tap do |attrs|
              attrs[:invalid] = 'yes' if identifier.status == 'invalid'
            end.compact
            xml.recordIdentifier identifier.value || identifier.uri, id_attributes
          end
        end

        def build_language
          Array(admin_metadata.language).each do |language|
            language_of_cataloging_attrs = {}
            language_of_cataloging_attrs[:usage] = language.status if language.status
            xml.languageOfCataloging language_of_cataloging_attrs do
              language_attrs = with_uri_info(language, {})
              xml.languageTerm language.value, language_attrs.merge(type: 'text') if language.value
              xml.languageTerm language.code, language_attrs.merge(type: 'code')
              if language.script
                script_attrs = with_uri_info(language.script, {})
                xml.scriptTerm language.script.value, script_attrs.merge(type: 'text')
                xml.scriptTerm language.script.code, script_attrs.merge(type: 'code')
              end
            end
          end
        end

        def with_uri_info(cocina, xml_attrs = {})
          xml_attrs[:valueURI] = cocina.uri
          xml_attrs[:authorityURI] = cocina.source&.uri
          xml_attrs[:authority] = cocina.source&.code
          xml_attrs.compact
        end
      end
    end
  end
end
