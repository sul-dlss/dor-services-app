# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps language terms
      class LanguageTerm
        # @param [Nokogiri::XML::Element] language_element language or languageOfCataloging element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(language_element:, descriptive_builder: nil)
          new(language_element: language_element).build
        end

        def initialize(language_element:)
          @language_element = language_element
        end

        def build
          attribs = lang_term_attributes
          attribs[:status] = status
          attribs[:script] = script_term_attributes
          attribs.compact
        end

        private

        attr_reader :language_element

        def lang_term_attributes
          code_language_term = language_element.xpath('./mods:languageTerm[@type="code"]', mods: DESC_METADATA_NS).first
          text_language_term = language_element.xpath('./mods:languageTerm[@type="text"]', mods: DESC_METADATA_NS).first
          if code_language_term.nil? && text_language_term.nil?
            Honeybadger.notify('[DATA ERROR] languageTerm missing type', { tags: 'data_error' })
            code_language_term = language_element.xpath('./mods:languageTerm', mods: DESC_METADATA_NS).first
          end

          {
            code: code_language_term&.text,
            value: text_language_term&.text,
            uri: language_value_uri_for(code_language_term, text_language_term),
            appliesTo: language_applies_to,
            displayLabel: language_element['displayLabel']
          }.tap do |attrs|
            source = language_source_for(code_language_term, text_language_term)
            attrs[:source] = source if source.present?
          end
        end

        def script_term_attributes
          script_term_nodes = language_element.xpath('mods:scriptTerm', mods: DESC_METADATA_NS)

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

        # this can be present for type text and/or code, but we only want one.
        def language_value_uri_for(code_language_term, text_language_term)
          code_language_term&.attribute('valueURI')&.to_s || text_language_term&.attribute('valueURI')&.to_s
        end

        def language_applies_to
          value = language_element['objectPart']
          [value: value] if value.present?
        end

        def language_source_for(code_language_term, text_language_term)
          {
            code: code_language_term&.attribute('authority')&.to_s || text_language_term&.attribute('authority')&.to_s,
            uri: code_language_term&.attribute('authorityURI')&.to_s || text_language_term&.attribute('authorityURI')&.to_s

          }.compact
        end

        def status
          status_value = language_element[:usage] || language_element[:status]
          return unless status_value

          status_value.downcase.tap do |value|
            if status_value != value
              Honeybadger.notify("[DATA ERROR] #{language_element.name} usage attribute is set to \"#{language_element[:usage]}\"",
                                 { tags: 'data_error' })
            end
          end
        end
      end
    end
  end
end
