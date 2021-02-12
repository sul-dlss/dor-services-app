# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps languages
      class Language
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:, purl: nil)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
        end

        def build
          languages = resource_element.xpath('mods:language', mods: DESC_METADATA_NS).map do |lang_node|
            Cocina::FromFedora::Descriptive::LanguageTerm.build(language_element: lang_node, notifier: notifier)
          end
          Primary.adjust(languages, 'language', notifier)
        end

        private

        attr_reader :resource_element, :notifier
      end
    end
  end
end
