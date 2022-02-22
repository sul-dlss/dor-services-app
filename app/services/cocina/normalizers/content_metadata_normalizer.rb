# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object content metadata datastream, accounting for differences
    #   between Fedora contentMetadata and cocina structural that are valid but different
    #   when round-tripping.
    class ContentMetadataNormalizer
      include Cocina::Normalizers::Base
      FILE_DIRECTIVES = %i[publish preserve shelve].freeze

      # @param [String] druid
      # @param [Nokogiri::Document] content_ng_xml content metadata XML to be normalized
      # @return [Nokogiri::Document] normalized content metadata xml
      def self.normalize(druid:, content_ng_xml:)
        new(content_ng_xml: content_ng_xml).normalize(druid: druid)
      end

      # resource ids and sequence numbers are regenerated so they must be normalized out of the roundtrip comparison
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
        remove_resource_id_attribute
        remove_resource_objectid_attribute
        remove_resource_data_attribute
        remove_external_resource_id
        remove_resource_sequence_attribute
        remove_location
        remove_file_format_and_data_type_attributes
        remove_geodata
        remove_id_attribute
        remove_stacks_attribute
        remove_empty_labels
        remove_provider_checksum
        remove_meaningless_attr_elements
        remove_pagestart_attribute
        normalize_object_id_attribute(druid)
        normalize_reading_order(druid)
        normalize_attr_label
        normalize_file_deliver_attribute
        downcase_checksum_type
        normalize_empty_xml
        missing_type_attribute_assigned_file
        remove_empty_image_data
        remove_duplicate_image_data
        normalize_image_data_to_integers
        normalize_file_directives
        normalize_relationship
        normalize_empty_resources

        regenerate_ng_xml(ng_xml.to_s)
      end

      # resource ids and sequence numbers are regenerated so they must be normalized out of the roundtrip comparison
      def normalize_roundtrip
        remove_resource_id_attribute
        remove_external_resource_id
        remove_resource_sequence_attribute

        regenerate_ng_xml(ng_xml.to_s)
      end

      private

      attr_reader :ng_xml, :druid

      def remove_resource_id_attribute
        ng_xml.xpath('//resource/@id').each(&:remove)
      end

      def remove_resource_objectid_attribute
        ng_xml.xpath('//resource/@objectId').each(&:remove)
      end

      def remove_resource_data_attribute
        ng_xml.xpath('//resource/@data').each(&:remove)
      end

      def remove_empty_labels
        ng_xml.xpath('//label[not(text())][not(@*)]').each(&:remove)
      end

      # Some original content metadata does not have sequence for all resource nodes.
      # However, sequence is assigned to all resource nodes when mapping from cocina to fedora.
      def remove_resource_sequence_attribute
        ng_xml.xpath('//resource[@sequence]').each { |resource_node| resource_node.delete('sequence') }
      end

      def remove_location
        ng_xml.xpath('//location[@type="url"]').each(&:remove)
      end

      # remove empty width and height attributes from imageData, e.g. <imageData width="" height=""/>
      # then remove any totally empty imageData nodes, e.g. <imageData/>
      def remove_empty_image_data
        ng_xml.xpath('//imageData[@height=""]').each { |node| node.remove_attribute('height') }
        ng_xml.xpath('//imageData[@width=""]').each { |node| node.remove_attribute('width') }
        ng_xml.xpath('//imageData[not(text())][not(@*)]').each(&:remove)
      end

      # convert any imageData to integers and ditch any units <imageData width="27.544308mm" height="29.510118mm"/>
      # goes to <imageData width="27" height="29"/>
      def normalize_image_data_to_integers
        ng_xml.xpath('//imageData[not(@height="")]').each { |node| node['height'] = node['height'].to_i if node['height'] }
        ng_xml.xpath('//imageData[not(@width="")]').each { |node| node['width'] = node['width'].to_i if node['width'] }
      end

      def remove_duplicate_image_data
        ng_xml.xpath('//file[imageData]').each do |file_node|
          image_data_nodeset = file_node.xpath('./imageData')
          next if image_data_nodeset.size == 1

          first = image_data_nodeset.first
          image_data_nodeset[1..].each do |image_data_node|
            image_data_node.remove if image_data_node['height'] == first['height'] &&
                                      image_data_node['width'] == first['width']
          end
        end
      end

      def normalize_object_id_attribute(druid)
        object_id = ng_xml.root['objectId']

        if object_id
          return if object_id.start_with?('druid:')

          ng_xml.root['objectId'] = "druid:#{object_id}"
        else
          ng_xml.root['objectId'] = druid
        end
      end

      def remove_file_format_and_data_type_attributes
        ng_xml.xpath('//file/@format').each(&:remove)
        ng_xml.xpath('//file/@dataType').each(&:remove)
      end

      # the geoData information is in descMetadata
      def remove_geodata
        ng_xml.xpath('//geoData').each(&:remove)
      end

      def remove_id_attribute
        ng_xml.xpath('/contentMetadata/@id').each(&:remove)
      end

      def remove_stacks_attribute
        ng_xml.xpath('/contentMetadata/@stacks').each(&:remove)
      end

      def remove_provider_checksum
        ng_xml.xpath('//resource/file/provider_checksum').each(&:remove)
      end

      def remove_pagestart_attribute
        ng_xml.xpath('//bookData/@pageStart').each(&:remove)
      end

      def normalize_reading_order(druid)
        return if ng_xml.root['type'] != 'book'
        return if ng_xml.xpath('//bookData[@readingOrder]').present?

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

      def normalize_attr_label
        ng_xml.xpath('//attr[@type="label"] | //attr[@name="label"]').each do |attr_node|
          if attr_node.content.present? # don't create new blank labels
            label_node = Nokogiri::XML::Node.new('label', ng_xml)
            label_node.content = attr_node.content
            attr_node.parent << label_node
          end
          attr_node.remove
        end
      end

      # publish, shelve, preserve
      def normalize_file_directives
        FILE_DIRECTIVES.each do |directive|
          ng_xml.xpath("//file[@#{directive}]").each do |node|
            node[directive] = 'no' if node[directive] == ''
            node[directive] = node[directive].strip
          end
        end
      end

      def remove_meaningless_attr_elements
        ng_xml.xpath('//attr[@name="mergedFromResource" or @name="mergedFromPid" or @name="representation"]').each(&:remove)
      end

      def normalize_file_deliver_attribute
        ng_xml.xpath('//file').each do |file|
          file['publish'] ||= file['deliver']
          file.delete('deliver')
        end
      end

      def downcase_checksum_type
        ng_xml.xpath('//file/checksum/@type').each { |checksum_type| checksum_type.value = checksum_type.value.downcase }
      end

      # some objects have <xml> instead of <contentMetadata>, e.g. normalize <xml type="file"/> --> <contentMetadata type="file"/>
      def normalize_empty_xml
        ng_xml.xpath('//xml[not(text())]').each { |node| node.name = 'contentMetadata' }
      end

      # set the type attribute on the contentMetadata node when it's missing
      def missing_type_attribute_assigned_file
        ng_xml.xpath('//contentMetadata[not(@type)]').each do |node|
          node['type'] = 'file'
        end
      end

      def remove_external_resource_id
        ng_xml.xpath('//externalFile/@resourceId').each(&:remove)
      end

      def normalize_relationship
        ng_xml.root.xpath('//relationship[not(@type)]').each do |node|
          node['type'] = 'alsoAvailableAs'
        end
      end

      def normalize_empty_resources
        ng_xml.root.xpath('//resource[not(file) and not(externalFile)]').each(&:remove)
      end
    end
  end
end
