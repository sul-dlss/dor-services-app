# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object rights datastream, accounting for differences between Fedora rights and cocina rights that are valid but different
    # when round-tripping.
    class RightsNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] the rights datastream to be normalized
      # @return [Nokogiri::Document] normalized rights xml
      # Note: this is different than other normalizers in that it takes in a datastream as a parameter instead of the XML
      #  because we use an existing class below to fetch the license URI and this class requires a datastream
      def self.normalize(datastream:)
        new(datastream: datastream).normalize
      end

      def initialize(datastream:)
        @datastream = datastream
        @ng_xml = datastream.ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # sometimes it's a String (?)
      end

      def normalize
        normalize_license_to_uri
        remove_embargo_release_date
        normalize_group
        normalize_use_and_reproduction
        normalize_discover
        regenerate_ng_xml(ng_xml.to_s)
      end

      private

      attr_reader :ng_xml, :datastream

      def license_nodes(xml)
        xml.root.xpath('//license')
      end

      def normalize_license_to_uri
        # first remove old style license nodes
        ['openDataCommons', 'creativeCommons'].each do |license_type|
          ng_xml.root.xpath("//use/machine[@type='#{license_type}' and text()]").each(&:remove)
          ng_xml.root.xpath("//use/human[@type='#{license_type}' and text()]").each(&:remove)
        end
        # now add new <license> node
        license_uri = Cocina::FromFedora::Access::License.find(datastream)
        new_license_node = Nokogiri::XML::Node.new('license', ng_xml)
        new_license_node.content = license_uri
        ng_xml.at('//use') << new_license_node if license_uri.present?
        ng_xml.root.xpath('//use[count(*) = 0]').each(&:remove)
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
