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
        remove_format_and_data_type
        remove_geodata
        remove_id
        remove_stacks
        normalize_object_id(druid)
        normalize_reading_order(druid)
        normalize_label_attr
        normalize_attr
        normalize_publish
        normalize_empty_xml
        normalize_image_data

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

      def normalize_image_data
        # remove empty width and heigh attributes from imageData, e.g. <imageData width="" height=""/>
        # then remove any totally empty imageData nodes, e.g. <imageData/>
        ng_xml.root.xpath('//imageData[@height=""]').each { |node| node.remove_attribute('height') }
        ng_xml.root.xpath('//imageData[@width=""]').each { |node| node.remove_attribute('width') }
        ng_xml.root.xpath('//imageData[not(text())][not(@*)]').each(&:remove)
      end

      def normalize_object_id(druid)
        object_id = ng_xml.root['objectId']

        if object_id
          return if object_id.start_with?('druid:')

          ng_xml.root['objectId'] = "druid:#{object_id}"
        else
          ng_xml.root['objectId'] = druid
        end
      end

      def remove_format_and_data_type
        ng_xml.root.xpath('//file[@format]').each { |file_node| file_node.delete('format') }
        ng_xml.root.xpath('//file[@dataType]').each { |file_node| file_node.delete('dataType') }
      end

      def remove_geodata
        ng_xml.root.xpath('//geoData').each(&:remove)
      end

      def remove_id
        return if ng_xml.root['id'].blank?

        ng_xml.root.delete('id')
      end

      def remove_stacks
        return if ng_xml.root['stacks'].blank?

        ng_xml.root.delete('stacks')
      end

      def normalize_reading_order(druid)
        return if ng_xml.root['type'] != 'book'
        return if ng_xml.root.xpath('//bookData[@readingOrder]').present?

        reading_direction = Cocina::FromFedora::ViewingDirectionHelper.viewing_direction(druid: druid, content_ng_xml: ng_xml)
        fedora_reading_direction = case reading_direction
                                   when nil, 'left-to-right'
                                     'ltr'
                                   else
                                     'rtl'
                                   end

        book_data_node = Nokogiri::XML::Node.new('bookData', ng_xml)
        book_data_node['readingOrder'] = fedora_reading_direction
        ng_xml.root << book_data_node
      end

      def normalize_label_attr
        ng_xml.root.xpath('//attr[@type="label"] | //attr[@name="label"]').each do |attr_node|
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

      def normalize_empty_xml
        # some objects have <xml> instead of <contentMetadata>, e.g. normalize <xml type="file"/> --> <contentMetadata type="file"/>
        ng_xml.root.xpath('//xml[not(text())]').each { |node| node.name = 'contentMetadata' }
      end
    end
  end
end
