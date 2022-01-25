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
        remove_resource_objectid
        remove_resource_data
        remove_sequence
        remove_location
        remove_format
        normalize_object_id
        normalize_reading_order(druid)
        normalize_label_attr
        normalize_attr
        normalize_publish

        regenerate_ng_xml(ng_xml.to_s)
      end

      def normalize_roundtrip
        remove_resource_id
        remove_sequence

        regenerate_ng_xml(ng_xml.to_s)
      end

      private

      attr_reader :ng_xml, :druid

      def remove_resource_id
        ng_xml.root.xpath('//resource[@id]').each { |resource_node| resource_node.delete('id') }
      end

      def remove_resource_objectid
        ng_xml.root.xpath('//resource[@objectId]').each { |resource_node| resource_node.delete('objectId') }
      end

      def remove_resource_data
        ng_xml.root.xpath('//resource[@data]').each { |resource_node| resource_node.delete('data') }
      end

      def remove_sequence
        # Some original content metadata does not have sequence for all resource nodes.
        # However, sequence is assigned to all resource nodes when mapping to fedora.
        ng_xml.root.xpath('//resource[@sequence]').each { |resource_node| resource_node.delete('sequence') }
      end

      def remove_location
        ng_xml.root.xpath('//location[@type="url"]').each(&:remove)
      end

      def normalize_object_id
        object_id = ng_xml.root['objectId']
        return if object_id.nil? || object_id.start_with?('druid:')

        ng_xml.root['objectId'] = "druid:#{object_id}"
      end

      def remove_format
        ng_xml.root.xpath('//file[@format]').each { |file_node| file_node.delete('format') }
      end

      def normalize_reading_order(druid)
        return if ng_xml.root['type'] != 'book'
        return if ng_xml.root.xpath('//bookData[@readingOrder]').present?
        return if ng_xml.root.xpath('//resource').empty?

        reading_direction = Cocina::FromFedora::ViewingDirectionHelper.viewing_direction(druid: druid, content_ng_xml: ng_xml)
        return unless reading_direction

        book_data_node = Nokogiri::XML::Node.new('bookData', ng_xml)
        book_data_node['readingOrder'] = reading_direction == 'left-to-right' ? 'ltr' : 'rtl'
        ng_xml.root << book_data_node
      end

      def normalize_label_attr
        # Pending https://github.com/sul-dlss/dor-services-app/issues/2808
        ng_xml.root.xpath('//attr[@type="label"]').each do |attr_node|
          label_node = Nokogiri::XML::Node.new('label', ng_xml)
          label_node.content = attr_node.content
          attr_node.parent << label_node
          attr_node.remove
        end
      end

      def normalize_attr
        ng_xml.root.xpath('//attr[@name="mergedFromResource" or @name="mergedFromPid" or @name="representation"]').each(&:remove)
      end

      def normalize_publish
        ng_xml.root.xpath('//file').each do |file|
          file['publish'] ||= file['deliver']
          file.delete('deliver')
        end
      end
    end
  end
end
