# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps titles
      class Titles
        TYPES = {
          'nonSort' => 'nonsorting characters',
          'title' => 'main title',
          'subTitle' => 'subtitle',
          'partNumber' => 'part number',
          'partName' => 'part name'
        }.freeze

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          title_infos_with_groups = ng_xml.xpath('//mods:mods/mods:titleInfo[@altRepGroup]', mods: DESC_METADATA_NS)
          grouped_title_infos = title_infos_with_groups.group_by { |node| node['altRepGroup'] }

          result = grouped_title_infos.map { |_k, node_set| { parallelValue: simple_or_structured(node_set) } }

          title_infos_without_groups = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@altRepGroup)]', mods: DESC_METADATA_NS)
          result += simple_or_structured(title_infos_without_groups)
          result
        end

        private

        attr_reader :ng_xml

        def simple_or_structured(node_set)
          node_set.map { |node| title_info_to_simple_or_structured(node) }
        end

        # @param [Nokogiri::XML::Element] title_info the titleInfo node
        def title_info_to_simple_or_structured(title_info)
          # Find all the child nodes that have text
          children = title_info.xpath('./*[child::node()[self::text()]]')
          raise Mapper::MissingTitle if children.empty?

          # Is this a basic title or a title with parts
          return simple_value(title_info) if children.map(&:name) == ['title']

          with_attributes({ structuredValue: structured_value(children) }, title_info)
        end

        # @param [Nokogiri::XML::Element] node the titleInfo node
        def simple_value(node)
          with_attributes({ value: node.xpath('./mods:title', mods: DESC_METADATA_NS).text }, node)
        end

        # @param [Hash<Symbol,String>] value
        # @param [Nokogiri::XML::Element] title_info the titleInfo node
        def with_attributes(value, title_info)
          value.tap do |result|
            result[:status] = 'primary' if title_info['usage'] == 'primary'
            result[:type] = title_info['type'] if title_info['type']
            result[:language] = [{ code: title_info['lang'], source: { code: 'iso639-2b' } }] if title_info['lang']
          end
        end

        # @param [Nokogiri::XML::NodeSet] child_nodes the children of the titleInfo
        def structured_value(child_nodes)
          new_nodes = child_nodes.map do |node|
            { value: node.text, type: TYPES[node.name] }
          end

          unsortable = child_nodes.select { |node| node.name == 'nonSort' }
          if unsortable.any?
            new_nodes << {
              "note": [
                {
                  "value": unsortable.sum do |node|
                    add = node.text.end_with?('-') || node.text.end_with?("'") ? 0 : 1
                    node.text.size + add
                  end,
                  "type": 'nonsorting character count'
                }
              ]
            }
          end

          new_nodes
        end
      end
    end
  end
end
