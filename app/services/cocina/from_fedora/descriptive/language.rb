# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps languages
      class Language
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
          [].tap do |langs|
            languages.each do |lang|
              attribs = lang_term_attributes_for(lang)
              attribs[:status] = lang['status']
              attribs[:script] = script_term_attributes_for(lang)
              langs << attribs.compact
            end
          end
        end

        private

        attr_reader :resource_element

        def lang_term_attributes_for(lang)
          code_language_term = lang.xpath('./mods:languageTerm[@type="code"]', mods: DESC_METADATA_NS).first
          text_language_term = lang.xpath('./mods:languageTerm[@type="text"]', mods: DESC_METADATA_NS).first
          if code_language_term.nil? && text_language_term.nil?
            Honeybadger.notify('[DATA ERROR] languageTerm missing type', { tags: 'data_error' })
            code_language_term = lang.xpath('./mods:languageTerm', mods: DESC_METADATA_NS).first
          end

          {
            code: code_language_term&.text,
            value: text_language_term&.text,
            uri: language_value_uri_for(code_language_term, text_language_term),
            appliesTo: language_applies_to(lang),
            displayLabel: lang['displayLabel']
          }.tap do |attrs|
            source = language_source_for(code_language_term, text_language_term)
            attrs[:source] = source if source.present?
          end
        end

        def script_term_attributes_for(lang)
          script_term_nodes = lang.xpath('mods:scriptTerm', mods: DESC_METADATA_NS)

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
          @languages ||= resource_element.xpath('mods:language', mods: DESC_METADATA_NS)
        end

        # this can be present for type text and/or code, but we only want one.
        def language_value_uri_for(code_language_term, text_language_term)
          code_language_term&.attribute('valueURI')&.to_s || text_language_term&.attribute('valueURI')&.to_s
        end

        def language_applies_to(lang)
          value = lang['objectPart']
          [value: value] if value.present?
        end

        def language_source_for(code_language_term, text_language_term)
          {
            code: code_language_term&.attribute('authority')&.to_s || text_language_term&.attribute('authority')&.to_s,
            uri: code_language_term&.attribute('authorityURI')&.to_s || text_language_term&.attribute('authorityURI')&.to_s

          }.compact
        end
      end
    end
  end
end
