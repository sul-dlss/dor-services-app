# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object adminMetadata datastream, accounting for differences between Fedora and cocina that are valid but differ when round-tripping.
    class AdminNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] admin_ng_xml admin metadata XML to be normalized
      # @return [Nokogiri::Document] normalized admin metadata xml
      def self.normalize(admin_ng_xml:)
        new(admin_ng_xml: admin_ng_xml).normalize
      end

      def initialize(admin_ng_xml:)
        @ng_xml = admin_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # following pattern from other normalizers
      end

      def normalize
        normalize_desc_metadata_nodes
        normalize_empty_registration_and_dissemination
        regenerate_ng_xml(ng_xml.to_xml)
      end

      private

      attr_reader :ng_xml

      def normalize_desc_metadata_nodes
        # removes any nodes like this: <descMetadata><format>MODS</format><descMetadata>
        ng_xml.root.xpath('//descMetadata/format[text()="MODS"]').each { |node| node.parent.remove }
      end

      def normalize_empty_registration_and_dissemination
        # removes any empty nodes like this: <registration/> or <dissemation/>
        ng_xml.root.xpath('//registration[not(node())]').each(&:remove)
        ng_xml.root.xpath('//dissemination[not(node())]').each(&:remove)
      end
    end
  end
end
