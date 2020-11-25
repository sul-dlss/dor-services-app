# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps lang and script attributes
      class LanguageScript
        # @param [Nokogiri::XML::Element] element that may have lang or script attributes
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @return [Hash] a hash that can be mapped to a cocina model for a valueLanguage
        def self.build(node:)
          return nil unless node['lang'].present? || node['script'].present?

          {}.tap do |value_language|
            if node['lang'].present?
              value_language[:code] = node['lang']
              value_language[:source] = { code: 'iso639-2b' }
            end
            value_language[:valueScript] = { code: node['script'], source: { code: 'iso15924' } } if node['script'].present?
          end
        end
      end
    end
  end
end
