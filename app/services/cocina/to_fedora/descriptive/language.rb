# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps languages from cocina to MODS XML
      class Language
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::Language>] languages
        def self.write(xml:, languages:)
          new(xml: xml, languages: languages).write
        end

        def initialize(xml:, languages:)
          @xml = xml
          @languages = languages
        end

        def write
          Array(languages).each do |language|
            write_basic(language)
          end
        end

        private

        attr_reader :xml, :languages

        # rubocop:disable Metrics/AbcSize
        def write_basic(language)
          top_attributes = {}
          top_attributes[:displayLabel] = language.displayLabel if language.displayLabel
          applies_to = applies_to_first_value(language.appliesTo)
          top_attributes[:objectPart] = applies_to if applies_to
          top_attributes[:usage] = language.status if language.status
          xml.language top_attributes do
            attributes = {}
            attributes[:valueURI] = language.uri if language.uri
            attributes[:authorityURI] = language.source.uri if language.source&.uri
            attributes[:authority] = language.source.code if language.source&.code

            if language.value
              attributes[:type] = 'text'
              xml.languageTerm language.value, attributes
            end

            if language.code
              attributes[:type] = 'code'
              xml.languageTerm language.code, attributes
            end

            write_script(language.script) if language.script
          end
        end
        # rubocop:enable Metrics/AbcSize

        def write_script(script)
          attributes = {}
          attributes[:authority] = script.source.code if script.source&.code

          if script.value
            attributes[:type] = 'text'
            xml.scriptTerm script.value, attributes
          end

          return unless script.code

          attributes[:type] = 'code'
          xml.scriptTerm script.code, attributes
        end

        # NOTE: appliesTo is an array in cocina model, but it is an xml attribute (thus single value) in MODS ...
        # get value from DescriptiveBasicValue
        def applies_to_first_value(applies_to)
          applies_to&.first&.value
        end
      end
    end
  end
end
