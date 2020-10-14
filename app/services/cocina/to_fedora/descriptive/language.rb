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
          Array(languages).each_with_index do |language, _alt_rep_group|
            write_basic(language)
          end
        end

        private

        attr_reader :xml, :languages

        def write_basic(language)
          xml.language do
            if language.value
              xml.languageTerm language.value, type: 'text'
            else
              attributes = { type: 'code' }
              attributes[:authority] = language.source.code
              xml.languageTerm language.code, attributes
            end
          end
        end
      end
    end
  end
end
