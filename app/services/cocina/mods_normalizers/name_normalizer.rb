# frozen_string_literal: true

module Cocina
  module ModsNormalizers
    # Normalizes a Fedora MODS document for name elements.
    class NameNormalizer
      # @param [Nokogiri::Document] mods_ng_xml MODS to be normalized
      # @return [Nokogiri::Document] normalized MODS
      def self.normalize(mods_ng_xml:)
        new(mods_ng_xml: mods_ng_xml).normalize
      end

      def initialize(mods_ng_xml:)
        @ng_xml = mods_ng_xml.dup
      end

      def normalize
        normalize_text_role_term
        normalize_name
        ng_xml
      end

      private

      attr_reader :ng_xml

      def normalize_text_role_term
        ng_xml.root.xpath("//mods:roleTerm[@type='text']", mods: ModsNormalizer::MODS_NS).each do |role_term_node|
          role_term_node.content = role_term_node.content.downcase
        end

        # Add the type="text" attribute to roleTerms that don't have a type (seen in MODS 3.3 druid:yy910cj7795)
        ng_xml.root.xpath('//mods:roleTerm[not(@type)]', mods: ModsNormalizer::MODS_NS).each do |role_term_node|
          role_term_node['type'] = 'text'
        end
      end

      def normalize_name
        ng_xml.root.xpath('//mods:namePart[not(text())]', mods: ModsNormalizer::MODS_NS).each(&:remove)
        ng_xml.root.xpath('//mods:name[not(mods:namePart) and not(@xlink:href)]', mods: ModsNormalizer::MODS_NS, xlink: ModsNormalizer::XLINK_NS).each(&:remove)

        # Some MODS 3.3 items have xlink:href attributes. See https://argo.stanford.edu/view/druid:yy910cj7795
        # Move them only when there are children.
        ng_xml.xpath('//mods:name[@xlink:href and mods:*]', mods: ModsNormalizer::MODS_NS, xlink: ModsNormalizer::XLINK_NS).each do |node|
          node['valueURI'] = node.remove_attribute('href').value
        end
      end
    end
  end
end
