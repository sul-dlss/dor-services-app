# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps languages
      class Language
        LANG_XPATH = '//mods:language'
        LANG_STATUS_XPATH = './@status'
        OBJECT_PART_XPATH = './@objectPart'
        DISPLAY_LABEL_XPATH = './@displayLabel'
        LANGUAGE_TERM_XPATH = "#{LANG_XPATH}/mods:languageTerm"
        SCRIPT_TERM_XPATH = "#{LANG_XPATH}/mods:scriptTerm"
        LANG_TERM_TEXT_XPATH = './mods:languageTerm[@type="text"]/text()'
        LANG_TERM_CODE_XPATH = './mods:languageTerm[@type="code"]/text()'
        LANG_TERM_CODE_AUTHORITY_XPATH = './mods:languageTerm[@type="code"]/@authority'
        LANG_TERM_TEXT_AUTHORITY_XPATH = './mods:languageTerm[@type="text"]/@authority'
        TEXT_AUTHORITY_URI_XPATH = './*[@type="text"]/@authorityURI' # can be for languageTerm or scriptTerm
        TEXT_VALUE_URI_XPATH = './*[@type="text"]/@valueURI' # can be for languageTerm or scriptTerm

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          [].tap do |langs|
            languages.each do |lang|
              attribs = {}
              attribs = lang_term_attributes_for(lang) if language_term?(lang)
              attribs[:status] = language_status_for(lang) if language_status_for(lang).present?
              attribs[:script] = script_term_attributes_for(script_term_nodes(lang)) if script_term?(lang)

              langs << attribs
            end
          end
        end

        private

        attr_reader :ng_xml

        def lang_term_attributes_for(lang)
          {
            code: language_code_for(lang),
            value: language_text_for(lang),
            uri: language_value_uri_for(lang),
            appliesTo: language_applies_to(lang),
            displayLabel: language_display_label(lang),
            source: language_source_for(lang)
          }.reject { |_k, v| v.blank? }
        end

        def script_term_attributes_for(script_term_nodes)
          return if script_term_nodes.blank?

          code, value, authority = nil
          script_term_nodes.each do |script_term_node|
            code ||= script_term_node.content if script_term_node['type'] == 'code'
            value ||= script_term_node.content if script_term_node['type'] == 'text'
            authority ||= script_term_node['authority']
          end
          source = { code: authority } if authority
          {
            code: code,
            value: value,
            source: source
          }.compact
        end

        def languages
          @languages ||= ng_xml.xpath(LANG_XPATH, mods: DESC_METADATA_NS)
        end

        def language_code_for(lang)
          lang.xpath(LANG_TERM_CODE_XPATH, mods: DESC_METADATA_NS).to_s if language_term?(lang)
        end

        def language_text_for(lang)
          lang.xpath(LANG_TERM_TEXT_XPATH, mods: DESC_METADATA_NS).to_s if language_term?(lang)
        end

        # this can be present for type text and/or code, but we only want one.
        def language_value_uri_for(lang)
          result = lang.xpath(TEXT_VALUE_URI_XPATH, mods: DESC_METADATA_NS).to_s
          result = lang.xpath('./*/@valueURI', mods: DESC_METADATA_NS).to_s if result.blank?
          result
        end

        def language_applies_to(lang)
          value = lang.xpath(OBJECT_PART_XPATH, mods: DESC_METADATA_NS).to_s
          [value: value] if value.present?
        end

        def language_display_label(lang)
          lang.xpath(DISPLAY_LABEL_XPATH, mods: DESC_METADATA_NS).to_s
        end

        def language_status_for(lang)
          lang.xpath(LANG_STATUS_XPATH, mods: DESC_METADATA_NS).to_s
        end

        def language_source_for(lang)
          code = lang.xpath(LANG_TERM_CODE_AUTHORITY_XPATH, mods: DESC_METADATA_NS).to_s if language_term?(lang)
          # in case there is only a text node
          code = lang.xpath(LANG_TERM_TEXT_AUTHORITY_XPATH, mods: DESC_METADATA_NS).to_s if code.blank? && language_term?(lang)
          # this can be present for type text and/or code, but we only want one.
          uri = lang.xpath(TEXT_AUTHORITY_URI_XPATH, mods: DESC_METADATA_NS).to_s
          uri = lang.xpath('./*/@authorityURI', mods: DESC_METADATA_NS).to_s if uri.blank?
          {
            code: code,
            uri: uri
          }.reject { |_k, v| v.blank? }
        end

        def language_term?(lang)
          lang.xpath(LANGUAGE_TERM_XPATH, mods: DESC_METADATA_NS).to_s.present?
        end

        def script_term?(lang)
          script_term_nodes(lang).to_s.present?
        end

        def script_term_nodes(lang)
          lang.xpath(SCRIPT_TERM_XPATH, mods: DESC_METADATA_NS)
        end
      end
    end
  end
end
