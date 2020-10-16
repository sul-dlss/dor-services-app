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
            source = admin_metadata.contributor.first.name.first
            xml.recordContentSource source.code, with_uri_info(source)
            xml.descriptionStandard with_uri_info(admin_metadata.standard).merge(authority: admin_metadata.standard.code)
            xml.recordOrigin admin_metadata.note.find { |note| note.type == 'record origin' }.value
          end
        end

        private

        attr_reader :xml, :admin_metadata

        def build_language
          admin_metadata.language.each do |language|
            xml.languageOfCataloging usage: 'primary' do
              language_attrs = with_uri_info(language, {})
              xml.languageTerm language.value, language_attrs.merge(type: 'text')
              xml.languageTerm language.code, language_attrs.merge(type: 'code')
              script_attrs = with_uri_info(language.script, {})
              xml.scriptTerm language.script.value, script_attrs.merge(type: 'text')
              xml.scriptTerm language.script.code, script_attrs.merge(type: 'code')
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
