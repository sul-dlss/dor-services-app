# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object rights datastream, accounting for differences between Fedora rights and cocina rights that are valid but different
    # when round-tripping.
    class RightsNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] rights_ng_xml rights XML to be normalized
      # @return [Nokogiri::Document] normalized rights xml
      def self.normalize(rights_ng_xml:)
        new(rights_ng_xml: rights_ng_xml).normalize
      end

      # @param [Nokogiri::Document] roundtripped rights_ng_xml rights XML to be normalized
      # @return [Nokogiri::Document] normalized roundtripped rights xml
      def self.normalize_roundtrip(rights_ng_xml:, original_ng_xml:)
        new(rights_ng_xml: rights_ng_xml).normalize_roundtrip(original_ng_xml)
      end

      def initialize(rights_ng_xml:)
        @ng_xml = rights_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # sometimes it's a String (?)
      end

      def normalize
        remove_license
        remove_embargo_release_date
        normalize_group
        normalize_use_and_reproduction
        normalize_discover
        regenerate_ng_xml(ng_xml.to_s)
      end

      def normalize_roundtrip(original_ng_xml)
        normalize_roundtrip_ng_xml(original_ng_xml)
        regenerate_ng_xml(ng_xml.to_s)
      end

      private

      attr_reader :ng_xml

      def normalize_roundtrip_ng_xml(original_ng_xml)
        if license_nodes(original_ng_xml).blank?
          license_nodes(ng_xml).each do |license_node|
            use_node = license_node.parent
            license_node.remove
            use_node.remove if use_node.children.empty?
          end
        end
        regenerate_ng_xml(ng_xml.to_s)
      end

      def license_nodes(xml)
        xml.root.xpath('//license')
      end

      def remove_license
        ['openDataCommons', 'creativeCommons'].each do |license_type|
          ng_xml.root.xpath("//use/machine[@type='#{license_type}' and text()]").each(&:remove)
          ng_xml.root.xpath("//use/human[@type='#{license_type}' and text()]").each(&:remove)
        end
      end

      def remove_embargo_release_date
        ng_xml.root.xpath('//embargoReleaseDate').each(&:remove)
      end

      def normalize_group
        ng_xml.root.xpath('//group[text()]').each { |group_node| group_node.content = group_node.content.downcase }
      end

      def normalize_use_and_reproduction
        # Pending https://github.com/sul-dlss/dor-services-app/issues/2752
        ng_xml.root.xpath('//use/human[@type="useAndReproduction" and text()]').each { |human_node| human_node.content = human_node.content }
      end

      def normalize_discover
        # Multiple access discover nodes.
        discover_nodes = ng_xml.root.xpath('//access[@type="discover"]')
        discover_nodes[1, discover_nodes.size - 1].each(&:remove) if discover_nodes.size > 1
      end
    end
  end
end
