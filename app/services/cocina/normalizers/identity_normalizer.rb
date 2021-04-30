# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object identity metadata datastream, accounting for differences between Fedora rights and cocina rights that are valid but different
    # when round-tripping.
    class IdentityNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] identity_ng_xml identity metadata XML to be normalized
      # @return [Nokogiri::Document] normalized identity metadata xml
      def self.normalize(identity_ng_xml:)
        new(identity_ng_xml: identity_ng_xml).normalize
      end

      def initialize(identity_ng_xml:)
        @ng_xml = identity_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # sometimes it's a String (?)
      end

      def normalize
        normalize_source_id

        regenerate_ng_xml(ng_xml.to_s)
      end

      private

      attr_reader :ng_xml

      def normalize_source_id
        ng_xml.root.xpath('//sourceId').each do |source_node|
          source_node['source'] = source_node['source']&.strip
          source_node.content = source_node.content&.strip
        end
      end
    end
  end
end
