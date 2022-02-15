# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object embargo metadata datastream
    class EmbargoNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] embargo_ng_xml embargo metadata XML to be normalized
      # @return [Nokogiri::Document] normalized embargo metadata xml
      def self.normalize(embargo_ng_xml:)
        new(embargo_ng_xml: embargo_ng_xml).normalize
      end

      # @param [Nokogiri::Document] embargo_ng_xml embargo metadata XML to be normalized
      # @return [Nokogiri::Document] normalized embargo metadata xml
      def self.normalize_roundtrip(embargo_ng_xml:)
        new(embargo_ng_xml: embargo_ng_xml).normalize_roundtrip
      end

      def initialize(embargo_ng_xml:)
        @ng_xml = embargo_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # sometimes it's a String (?)
        regenerate_ng_xml(ng_xml.to_xml)
      end

      def normalize
        return ng_xml.to_xml if normalize_released?

        normalize_missing_discover
        normalize_twentypct
        normalize_empty

        regenerate_ng_xml(ng_xml.to_xml)
      end

      def normalize_roundtrip
        normalize_roundtrip_twentypct

        regenerate_ng_xml(ng_xml.to_xml)
      end

      private

      attr_reader :ng_xml

      def normalize_empty
        ng_xml.root.xpath('*[not(text())][not(@*)]').each do |node|
          node.remove unless node.name == 'releaseAccess' && !node.children.empty?
        end
        ng_xml.root.remove if ng_xml.root.xpath('*').empty?
      end

      def normalize_twentypct
        return if ng_xml.root.xpath('//twentyPctVisibilityStatus[text() = "released"]').blank?

        ng_xml.root.xpath('//twentyPctVisibilityStatus').each(&:remove)
        ng_xml.root.xpath('//twentyPctVisibilityReleaseDate').each(&:remove)
      end

      def normalize_roundtrip_twentypct
        return unless ng_xml.root

        ng_xml.root.xpath('//twentyPctVisibilityStatus').each(&:remove)
        ng_xml.root.xpath('//twentyPctVisibilityReleaseDate').each(&:remove)
      end

      def normalize_released?
        return false if ng_xml.root.xpath('//status[text() = "released"]').blank?

        ng_xml.root.remove
        true
      end

      def normalize_missing_discover
        release_access_nodes = ng_xml.xpath('//releaseAccess[access[@type="read"]/machine/world][not(access[@type="discover"]/machine/world)]')

        release_access_nodes.each do |release_access_node|
          access_node = Nokogiri::XML::Node.new('access', ng_xml)
          access_node[:type] = 'discover'
          machine_node = Nokogiri::XML::Node.new('machine', ng_xml)
          machine_node << Nokogiri::XML::Node.new('world', ng_xml)
          access_node << machine_node
          release_access_node << access_node
        end
      end
    end
  end
end
