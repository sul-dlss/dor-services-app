# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object content metadata datastream, accounting for differences between Fedora rights and cocina rights that are valid but different
    # when round-tripping.
    class ContentMetadataNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] content_ng_xml content metadata XML to be normalized
      # @return [Nokogiri::Document] normalized content metadata xml
      def self.normalize(content_ng_xml:)
        new(content_ng_xml: content_ng_xml).normalize
      end

      def initialize(content_ng_xml:)
        @ng_xml = content_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # sometimes it's a String (?)
      end

      def normalize
        remove_resource_id
        normalize_object_id

        regenerate_ng_xml(ng_xml.to_s)
      end

      private

      attr_reader :ng_xml

      def remove_resource_id
        ng_xml.root.xpath('//resource[@id]').each { |resource_node| resource_node.delete('id') }
      end

      def normalize_object_id
        object_id = ng_xml.root['objectId']
        return if object_id.nil? || object_id.start_with?('druid:')

        ng_xml.root['objectId'] = "druid:#{object_id}"
      end
    end
  end
end
