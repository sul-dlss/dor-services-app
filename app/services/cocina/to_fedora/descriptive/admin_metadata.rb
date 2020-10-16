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
          xml.recordOrigin admin_metadata.note.find { |note| note.type == 'record origin' }.value
        end

        def build_content_source
          Array(admin_metadata.contributor).each do |contributor|
            source = contributor.name.first
            xml.recordContentSource source.code, with_uri_info(source)
          end
        end

        def build_description_standard
          return unless admin_metadata.standard

          if admin_metadata.standard.uri
            xml.descriptionStandard with_uri_info(admin_metadata.standard).merge(authority: admin_metadata.standard.code)
          else
            xml.descriptionStandard admin_metadata.standard.code
          end
        end

        def build_event
          Array(admin_metadata.event).select { |note| note.type == 'creation' }.each do |event|
            event.date.each do |date|
              xml.recordCreationDate date.value, encoding: date.encoding.code
            end
          end
        end

        def build_identifier
          Array(admin_metadata.identifier).each do |identifier|
            xml.recordIdentifier identifier.value, source: identifier.source.value
          end
        end

        def build_language
          Array(admin_metadata.language).each do |language|
            xml.languageOfCataloging usage: 'primary' do
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
