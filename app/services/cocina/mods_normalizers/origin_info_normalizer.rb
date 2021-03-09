# frozen_string_literal: true

module Cocina
  module ModsNormalizers
    # Normalizes a Fedora MODS document for originInfo elements.
    # Must be called after authorityURI attribs are normalized
    class OriginInfoNormalizer
      DATE_FIELDS = %w[dateIssued copyrightDate dateCreated dateCaptured dateValid dateOther dateModified].freeze

      # @param [Nokogiri::Document] mods_ng_xml MODS to be normalized
      # @return [Nokogiri::Document] normalized MODS
      def self.normalize(mods_ng_xml:)
        new(mods_ng_xml: mods_ng_xml).normalize
      end

      def initialize(mods_ng_xml:)
        @ng_xml = mods_ng_xml.dup
        @ng_xml.encoding = 'UTF-8'
      end

      def normalize
        remove_empty_child_elements
        remove_empty_origin_info # must be after remove_empty_child_elements
        normalize_legacy_mods_event_type
        place_term_type_normalization
        remove_trailing_period_from_date_values
        normalize_authority_marcountry
        ng_xml
      end

      private

      attr_reader :ng_xml

      # must be called before remove_empty_origin_info
      def remove_empty_child_elements
        ng_xml.root.xpath('//mods:originInfo/mods:*', mods: ModsNormalizer::MODS_NS).each do |child_node|
          # if a node has either of these 2 attributes, it could have meaning even without any content
          next if child_node.xpath('//*[@valueURI]').present?
          next if child_node.xpath('//*[@xlink:href]', xlink: ModsNormalizer::XLINK_NS).present?

          child_node.remove if child_node.content.blank?
        end
      end

      # must be after remove_empty_child_elements
      def remove_empty_origin_info
        ng_xml.root.xpath('//mods:originInfo[not(mods:*) and not(@*)]', mods: ModsNormalizer::MODS_NS).each(&:remove)
        # make sure we remove ones such as <originInfo eventType="publication"/>
        ng_xml.root.xpath('//mods:originInfo[not(mods:*) and not(text()[normalize-space()])]', mods: ModsNormalizer::MODS_NS).each(&:remove)
      end

      LEGACY_EVENT_TYPES_2_TYPE = Cocina::FromFedora::Descriptive::Event::LEGACY_EVENT_TYPES_2_TYPE

      # because eventType is a relatively new addition to the MODS schema, records converted from MARC to MODS prior
      #   to its introduction used displayLabel as a stopgap measure, with certain values
      # The same values were also sometimes used as eventType values themselves, and will be converted to our preferred vocab.
      def normalize_legacy_mods_event_type
        ng_xml.root.xpath('//mods:originInfo[@*]', mods: ModsNormalizer::MODS_NS).each do |origin_info_node|
          event_type = origin_info_node['eventType']
          event_type = origin_info_node['displayLabel'] if event_type.blank? &&
                                                           LEGACY_EVENT_TYPES_2_TYPE.key?(origin_info_node['displayLabel'])
          event_type = LEGACY_EVENT_TYPES_2_TYPE[event_type] if LEGACY_EVENT_TYPES_2_TYPE.key?(event_type)

          origin_info_node['eventType'] = event_type if event_type.present?
          origin_info_node.delete('displayLabel') if event_type.present? &&
                                                     event_type == LEGACY_EVENT_TYPES_2_TYPE[origin_info_node['displayLabel']]
        end
      end

      # if the cocina model doesn't have a code, then it will have a value;
      #   this is output as attribute type=text on the roundtripped placeTerm element
      def place_term_type_normalization
        ng_xml.root.xpath('//mods:originInfo/mods:place/mods:placeTerm', mods: ModsNormalizer::MODS_NS).each do |place_term_node|
          next if place_term_node.content.blank?

          place_term_node['type'] = 'text' if place_term_node.attributes['type'].blank?
        end
      end

      def remove_trailing_period_from_date_values
        DATE_FIELDS.each do |date_field|
          ng_xml.root.xpath("//mods:originInfo/mods:#{date_field}", mods: ModsNormalizer::MODS_NS)
                .each { |date_node| date_node.content = date_node.content.delete_suffix('.') }
        end
      end

      def publisher_attribs_normalization
        ng_xml.root.xpath('//mods:publisher[@lang]', mods: ModsNormalizer::MODS_NS).each do |publisher_node|
          publisher_node.parent['lang'] = publisher_node['lang']
          publisher_node.delete('lang')
        end
        ng_xml.root.xpath('//mods:publisher[@script]', mods: ModsNormalizer::MODS_NS).each do |publisher_node|
          publisher_node.parent['script'] = publisher_node['script']
          publisher_node.delete('script')
        end
        ng_xml.root.xpath('//mods:publisher[@transliteration]', mods: ModsNormalizer::MODS_NS).each do |publisher_node|
          publisher_node.parent['transliteration'] = publisher_node['transliteration']
          publisher_node.delete('transliteration')
        end
      end

      def normalize_authority_marcountry
        ng_xml.root.xpath("//mods:*[@authority='marcountry']", mods: ModsNormalizer::MODS_NS).each do |node|
          node[:authority] = 'marccountry'
        end
      end
    end
  end
end
