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
      end

      def normalize
        remove_empty_origin_info_dates
        remove_empty_origin_info # must be after remove_empty_origin_info_dates
        normalize_origin_info_split
        normalize_origin_info_event_types
        normalize_origin_info_date_other_types # must be after normalize_origin_info_event_types
        normalize_origin_info_place_term_type
        normalize_origin_info_developed_date
        normalize_origin_info_date
        normalize_origin_info_publisher
        normalize_parallel_origin_info
        normalize_origin_info_lang_script
        ng_xml
      end

      private

      attr_reader :ng_xml

      # must be called before remove_empty_origin_info
      def remove_empty_origin_info_dates
        DATE_FIELDS.without('dateOther').each do |date_field|
          ng_xml.root.xpath("//mods:originInfo/mods:#{date_field}", mods: ModsNormalizer::MODS_NS).each do |date_node|
            date_node.remove if date_node.content.blank?
          end
        end

        # we can also remove dateOther if it has no type attribute
        ng_xml.root.xpath('//mods:originInfo/mods:dateOther[not(@type)]', mods: ModsNormalizer::MODS_NS).each do |date_node|
          date_node.remove if date_node.content.blank?
        end
      end

      # must be after remove_empty_origin_info_dates
      def remove_empty_origin_info
        ng_xml.root.xpath('//mods:originInfo[not(mods:*) and not(@*)]', mods: ModsNormalizer::MODS_NS).each(&:remove)
      end

      def normalize_origin_info_split
        # Split a single originInfo into multiple.
        split_origin_info('dateIssued', 'copyrightDate', 'copyright')
        split_origin_info('dateIssued', 'dateCaptured', 'capture')
        split_origin_info('dateIssued', 'dateValid', 'validity')
        split_origin_info('copyrightDate', 'publisher', 'publication')
      end

      def split_origin_info(split_node_name1, split_node_name2, event_type)
        ng_xml.root.xpath("//mods:originInfo[mods:#{split_node_name1} and mods:#{split_node_name2}]", mods: ModsNormalizer::MODS_NS).each do |origin_info_node|
          new_origin_info_node = Nokogiri::XML::Node.new('originInfo', Nokogiri::XML(nil))
          new_origin_info_node['displayLabel'] = origin_info_node['displayLabel'] if origin_info_node['displayLabel']
          new_origin_info_node['eventType'] = event_type
          origin_info_node.parent << new_origin_info_node
          split_nodes = origin_info_node.xpath("mods:#{split_node_name2}", mods: ModsNormalizer::MODS_NS)
          split_nodes.each do |split_node|
            split_node.remove
            new_origin_info_node << split_node
          end
        end
      end

      # change original xml to have the event type that will be output
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def normalize_origin_info_event_types
        ng_xml.root.xpath('//mods:originInfo', mods: ModsNormalizer::MODS_NS).each do |origin_info_node|
          next if normalize_event_type(origin_info_node, 'dateIssued', 'publication', ->(oi_node) { oi_node['eventType'] != 'presentation' })

          copyright_date_nodes = origin_info_node.xpath('mods:copyrightDate', mods: ModsNormalizer::MODS_NS)
          if copyright_date_nodes.present?
            origin_info_node['eventType'] = 'copyright' if origin_info_node['eventType'] != 'copyright notice'
            next
          end

          next if normalize_event_type(origin_info_node, 'dateCreated', 'production')
          next if normalize_event_type(origin_info_node, 'dateCaptured', 'capture')
          next if normalize_event_type(origin_info_node, 'dateValid', 'validity')
          next if normalize_date_other_event_type(origin_info_node)

          event_type_nil_lambda = ->(oi_node) { oi_node['eventType'].nil? }

          next if normalize_event_type(origin_info_node, 'publisher', 'publication', event_type_nil_lambda)
          next if normalize_event_type(origin_info_node, 'edition', 'publication', event_type_nil_lambda)
          next if normalize_event_type(origin_info_node, 'issuance', 'publication', event_type_nil_lambda)
          next if normalize_event_type(origin_info_node, 'frequency', 'publication', event_type_nil_lambda)
          next if normalize_event_type(origin_info_node, 'place', 'publication', event_type_nil_lambda)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def normalize_date_other_event_type(origin_info_node)
        date_other_node = origin_info_node.xpath('mods:dateOther[@type]', mods: ModsNormalizer::MODS_NS).first
        return false unless date_other_node.present? &&
                            Cocina::ToFedora::Descriptive::Event::DATE_OTHER_TYPE.keys.include?(date_other_node['type']) &&
                            origin_info_node['eventType'].nil?

        origin_info_node['eventType'] = date_other_node['type']
        true
      end

      def normalize_event_type(origin_info_node, child_node_name, event_type, filter = nil)
        child_nodes = origin_info_node.xpath("mods:#{child_node_name}", mods: ModsNormalizer::MODS_NS)
        return false if child_nodes.blank?
        return false if filter && !filter.call(origin_info_node)

        origin_info_node['eventType'] = event_type
        true
      end

      # NOTE: must be run after normalize_origin_info_event_types
      # remove dateOther type attribute if it matches originInfo@eventType and if dateOther is empty
      def normalize_origin_info_date_other_types
        ng_xml.root.xpath('//mods:originInfo[@eventType]', mods: ModsNormalizer::MODS_NS).each do |origin_info_node|
          origin_info_event_type = origin_info_node['eventType']
          origin_info_node.xpath('mods:dateOther[@type]', mods: ModsNormalizer::MODS_NS).each do |date_other_node|
            next if date_other_node.content.present?

            date_other_node.remove_attribute('type') if origin_info_event_type.match?(date_other_node['type'])
            # TODO: Temporarily ignoring pending https://github.com/sul-dlss/dor-services-app/issues/2128
            # date_other_node.remove if date_other_node.content.blank?
          end
        end
      end

      # if the cocina model doesn't have a code, then it will have a value;
      #   this is output as attribute type=text on the roundtripped placeTerm element
      def normalize_origin_info_place_term_type
        ng_xml.root.xpath('//mods:originInfo/mods:place/mods:placeTerm', mods: ModsNormalizer::MODS_NS).each do |place_term_node|
          next if place_term_node.content.blank?

          place_term_node['type'] = 'text' if place_term_node.attributes['type'].blank?
        end
      end

      def normalize_origin_info_developed_date
        ng_xml.root.xpath('//mods:originInfo/mods:dateOther[@type="developed"]', mods: ModsNormalizer::MODS_NS).each do |date_other|
          next if date_other.parent['eventType'] == 'development'

          # Move to own originInfo
          new_origin_info = Nokogiri::XML::Node.new('originInfo', Nokogiri::XML(nil))
          new_origin_info[:eventType] = 'development'
          new_origin_info << date_other.dup
          date_other.parent.parent << new_origin_info
          date_other.remove
        end
      end

      def normalize_origin_info_date
        DATE_FIELDS.each do |date_field|
          ng_xml.root.xpath("//mods:originInfo/mods:#{date_field}", mods: ModsNormalizer::MODS_NS)
                .each { |date_node| date_node.content = date_node.content.delete_suffix('.') }
        end
      end

      def normalize_origin_info_publisher
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

      def normalize_parallel_origin_info
        # For grouped originInfos, if no lang or script or lang and script are the same then make sure other values present on all in group.
        altrepgroup_origin_info_nodes, _other_origin_info_nodes = Cocina::FromFedora::Descriptive::AltRepGroup.split(
          nodes: ng_xml.root.xpath('//mods:originInfo',
                                   mods: ModsNormalizer::MODS_NS)
        )

        altrepgroup_origin_info_nodes.each do |origin_info_nodes|
          lang_script_map = origin_info_nodes.group_by { |origin_info_node| [origin_info_node['lang'], origin_info_node['script']] }
          grouped_origin_info_nodes = lang_script_map.values.select { |nodes| nodes.size > 1 }
          grouped_origin_info_nodes.each do |origin_info_node_group|
            origin_info_node_group.each do |origin_info_node|
              other_origin_info_nodes = origin_info_node_group.reject { |check_origin_info_node| origin_info_node == check_origin_info_node }
              normalize_parallel_origin_info_nodes(origin_info_node, other_origin_info_nodes)
            end
          end
        end
      end

      def normalize_parallel_origin_info_nodes(from_node, to_nodes)
        from_node.elements.each do |child_node|
          to_nodes.each do |to_node|
            next if matching_origin_info_child_node?(child_node, to_node)

            to_node << child_node.dup
          end
        end
      end

      def matching_origin_info_child_node?(child_node, origin_info_node)
        origin_info_node.elements.any? do |other_child_node|
          if child_node.name == 'place' && other_child_node.name == 'place'
            child_placeterm_node = child_node.xpath('mods:placeTerm', mods: ModsNormalizer::MODS_NS).first
            other_child_placeterm_node = other_child_node.xpath('mods:placeTerm', mods: ModsNormalizer::MODS_NS).first
            child_placeterm_node && other_child_placeterm_node && child_placeterm_node['type'] == other_child_placeterm_node['type']
          else
            child_node.name == other_child_node.name && child_node.to_h == other_child_node.to_h
          end
        end
      end

      def normalize_origin_info_lang_script
        # Remove lang and script attributes if none of the children can be parallel.
        ng_xml.root.xpath('//mods:originInfo[@lang or @script]', mods: ModsNormalizer::MODS_NS).each do |origin_info_node|
          parallel_nodes = origin_info_node.xpath('mods:place/mods:placeTerm[not(@type="code")]', mods: ModsNormalizer::MODS_NS) \
          + origin_info_node.xpath('mods:dateIssued[not(@encoding)]', mods: ModsNormalizer::MODS_NS) \
          + origin_info_node.xpath('mods:publisher', mods: ModsNormalizer::MODS_NS) \
          + origin_info_node.xpath('mods:edition', mods: ModsNormalizer::MODS_NS)
          if parallel_nodes.empty?
            origin_info_node.delete('lang')
            origin_info_node.delete('script')
          end
        end
      end
    end
  end
end
