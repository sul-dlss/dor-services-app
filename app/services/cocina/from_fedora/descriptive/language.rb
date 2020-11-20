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
          {
            code: lang.xpath('./mods:languageTerm[@type="code"]/text()', mods: DESC_METADATA_NS).to_s,
            value: lang.xpath('./mods:languageTerm[@type="text"]/text()', mods: DESC_METADATA_NS).to_s,
            uri: language_value_uri_for(lang),
            appliesTo: language_applies_to(lang),
            displayLabel: lang['displayLabel'],
            source: language_source_for(lang)
          }.reject { |_k, v| v.blank? }
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
        def language_value_uri_for(lang)
          # can be for languageTerm or scriptTerm
          result = lang.xpath('./*[@type="text"]/@valueURI', mods: DESC_METADATA_NS).to_s
          result = lang.xpath('./*/@valueURI', mods: DESC_METADATA_NS).to_s if result.blank?
          result
        end

        def language_applies_to(lang)
          value = lang['objectPart']
          [value: value] if value.present?
        end

        def language_source_for(lang)
          code = lang.xpath('./mods:languageTerm[@type="code"]/@authority', mods: DESC_METADATA_NS).to_s
          # in case there is only a text node
          code = lang.xpath('./mods:languageTerm[@type="text"]/@authority', mods: DESC_METADATA_NS).to_s if code.blank?
          # this can be present on a languageTerm or a scriptTerm for type text and/or code, but we only want one.
          uri = lang.xpath('./*[@type="text"]/@authorityURI', mods: DESC_METADATA_NS).to_s
          uri = lang.xpath('./*/@authorityURI', mods: DESC_METADATA_NS).to_s if uri.blank?
          {
            code: code,
            uri: uri
          }.reject { |_k, v| v.blank? }
        end
      end
    end
  end
end
