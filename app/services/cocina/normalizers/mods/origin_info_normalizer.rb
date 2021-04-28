# frozen_string_literal: true

module Cocina
  module Normalizers
    module Mods
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
          place_term_authority_normalization # must be after place_term_type_normalization
          normalize_authority_marcountry
          single_key_date
          remove_trailing_period_from_date_values
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

        # must be called after remove_empty_child_elements
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

        # must be called before place_term_authority_normalization
        # if the cocina model doesn't have a code, then it will have a value;
        #   this is output as attribute type=text on the roundtripped placeTerm element
        def place_term_type_normalization
          ng_xml.root.xpath('//mods:originInfo/mods:place/mods:placeTerm', mods: ModsNormalizer::MODS_NS).each do |place_term_node|
            next if place_term_node.content.blank?

            place_term_node['type'] = 'text' if place_term_node.attributes['type'].blank?
          end
        end

        # must be called after place_term_type_normalization
        # if the MODS has a single place element with both text and code placeTerm elements, if the text
        # element has no authority attributes but the code element DOES have authority attributes, then both
        # the text and the code elements get the authority attributes from the code element.
        def place_term_authority_normalization
          ng_xml.root.xpath('//mods:originInfo/mods:place[mods:placeTerm/@type]', mods: ModsNormalizer::MODS_NS).each do |place_node|
            text_place_term_node = place_node.xpath("mods:placeTerm[not(@type='code')]", mods: ModsNormalizer::MODS_NS).first
            next unless text_place_term_node
            next if text_place_term_node.text.blank?

            code_place_term_node = place_node.xpath("mods:placeTerm[@type='code']", mods: ModsNormalizer::MODS_NS).first
            next unless code_place_term_node
            next if code_place_term_node.text.blank?

            text_authority_attributes = authority_attributes(text_place_term_node)
            code_authority_attributes = authority_attributes(code_place_term_node)

            # NOTE: deliberately skipping situation where text node has some authority info and code node
            #  has other authority info as we may never encounter this

            if text_authority_attributes.present? && code_authority_attributes.blank?
              text_authority_attributes.each do |key, val|
                code_place_term_node[key] = val
              end
              next
            end

            next if code_authority_attributes.blank? || text_authority_attributes.present?

            code_authority_attributes.each do |key, val|
              text_place_term_node[key] = val
            end
          end
        end

        def authority_attributes(ng_node)
          {
            valueURI: ng_node['valueURI'],
            authority: ng_node['authority'],
            authorityURI: ng_node['authorityURI']
          }.compact
        end

        def normalize_authority_marcountry
          ng_xml.root.xpath("//mods:*[@authority='marcountry']", mods: ModsNormalizer::MODS_NS).each do |node|
            node[:authority] = 'marccountry'
          end
        end

        def single_key_date
          DATE_FIELDS.each do |date_field|
            key_date_nodes = ng_xml.root.xpath("//mods:originInfo/mods:#{date_field}[@point and @keyDate='yes']", mods: ModsNormalizer::MODS_NS)
            next unless key_date_nodes.size == 2

            end_node = key_date_nodes.find { |node| node['point'] == 'end' }
            end_node.delete('keyDate') if end_node && end_node['keyDate'].present?
          end
        end

        def remove_trailing_period_from_date_values
          DATE_FIELDS.each do |date_field|
            ng_xml.root.xpath("//mods:originInfo/mods:#{date_field}", mods: ModsNormalizer::MODS_NS)
                  .each { |date_node| date_node.content = date_node.content.delete_suffix('.') }
          end
        end
      end
    end
  end
end
