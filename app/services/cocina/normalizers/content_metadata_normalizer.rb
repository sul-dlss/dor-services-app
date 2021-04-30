# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object content metadata datastream, accounting for differences between Fedora rights and cocina rights that are valid but different
    # when round-tripping.
    class ContentMetadataNormalizer
      include Cocina::Normalizers::Base

      # @param [String] druid
      # @param [Nokogiri::Document] content_ng_xml content metadata XML to be normalized
      # @return [Nokogiri::Document] normalized content metadata xml
      def self.normalize(druid:, content_ng_xml:)
        new(content_ng_xml: content_ng_xml).normalize(druid: druid)
      end

      # @param [Nokogiri::Document] content_ng_xml roundtripped content metadata XML to be normalized
      # @return [Nokogiri::Document] normalized content metadata xml
      def self.normalize_roundtrip(content_ng_xml:)
        new(content_ng_xml: content_ng_xml).normalize_roundtrip
      end

      def initialize(content_ng_xml:)
        @ng_xml = content_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # sometimes it's a String (?)
      end

      def normalize(druid:)
        remove_resource_id
        normalize_object_id
        normalize_reading_order(druid)

        regenerate_ng_xml(ng_xml.to_s)
      end

      def normalize_roundtrip
        remove_resource_id

        regenerate_ng_xml(ng_xml.to_s)
      end

      private

      attr_reader :ng_xml, :druid

      def remove_resource_id
        ng_xml.root.xpath('//resource[@id]').each { |resource_node| resource_node.delete('id') }
      end

      def normalize_object_id
        object_id = ng_xml.root['objectId']
        return if object_id.nil? || object_id.start_with?('druid:')

        ng_xml.root['objectId'] = "druid:#{object_id}"
      end

      def normalize_reading_order(druid)
        return if ng_xml.root['type'] != 'book'
        return if ng_xml.root.xpath('//bookData[@readingOrder]').present?

        reading_direction = Cocina::FromFedora::ViewingDirectionHelper.viewing_direction(druid: druid, content_ng_xml: ng_xml)
        return unless reading_direction

        book_data_node = Nokogiri::XML::Node.new('bookData', ng_xml.root)
        book_data_node['readingOrder'] = reading_direction == 'left-to-right' ? 'ltr' : 'rtl'
        ng_xml.root << book_data_node
      end
    end
  end
end
