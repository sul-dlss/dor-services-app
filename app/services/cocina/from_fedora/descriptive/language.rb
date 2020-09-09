# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps languages
      class Language
        LANG_XPATH = '//mods:language'
        LANG_TEXT_XPATH = './mods:languageTerm[@type="text"]/text()'
        LANG_TEXT_AUTHORITY_URI_XPATH = './mods:languageTerm[@type="text"]/@authorityURI'
        LANG_TEXT_VALUE_URI_XPATH = './mods:languageTerm[@type="text"]/@valueURI'
        LANG_CODE_XPATH = './mods:languageTerm[@type="code"]/text()'
        LANG_CODE_AUTHORITY_XPATH = './mods:languageTerm[@type="code"]/@authority'

        # @param [Dor::Item,Dor::Etd] item
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(item)
          new(item).build
        end

        def initialize(item)
          @item = item
        end

        def build
          [].tap do |langs|
            languages.each do |lang|
              langs << { code: language_code_for(lang),
                         value: language_text_for(lang),
                         uri: language_uri_for(lang),
                         source: language_source_for(lang) }.reject { |_k, v| v.blank? }
            end
          end
        end

        private

        attr_reader :item

        def languages
          @languages ||= item.descMetadata.ng_xml.xpath(LANG_XPATH, mods: DESC_METADATA_NS)
        end

        def language_code_for(lang)
          lang.xpath(LANG_CODE_XPATH, mods: DESC_METADATA_NS).to_s
        end

        def language_text_for(lang)
          lang.xpath(LANG_TEXT_XPATH, mods: DESC_METADATA_NS).to_s
        end

        def language_uri_for(lang)
          lang.xpath(LANG_TEXT_VALUE_URI_XPATH, mods: DESC_METADATA_NS).to_s
        end

        def language_source_for(lang)
          {
            code: lang.xpath(LANG_CODE_AUTHORITY_XPATH, mods: DESC_METADATA_NS).to_s,
            uri: lang.xpath(LANG_TEXT_AUTHORITY_URI_XPATH, mods: DESC_METADATA_NS).to_s
          }.reject { |_k, v| v.blank? }
        end
      end
    end
  end
end
