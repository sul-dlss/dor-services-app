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
        normalize_dupes
        ng_xml
      end

      private

      attr_reader :ng_xml

      def normalize_text_role_term
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

      def normalize_dupes
        normalize_dupes_for(ng_xml.root)
        ng_xml.root.xpath('mods:relatedItem', mods: ModsNormalizer::MODS_NS).each { |related_item_node| normalize_dupes_for(related_item_node) }
      end

      def normalize_dupes_for(base_node)
        name_nodes = base_node.xpath('mods:name', mods: ModsNormalizer::MODS_NS)

        dupe_name_nodes_groups = name_nodes.group_by(&:to_s).values.select { |grouped_name_nodes| grouped_name_nodes.size > 1 }
        dupe_name_nodes_groups.each do |dupe_name_nodes|
          dupe_name_nodes[1..].each(&:remove)
        end
      end
    end
  end
end
