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

          result = grouped_title_infos.map { |_k, node_set| parallel(node_set) }

          title_infos_without_groups = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@altRepGroup)]', mods: DESC_METADATA_NS)
          result += simple_or_structured(title_infos_without_groups)
          result
        end

        private

        attr_reader :ng_xml

        # @param [Nokogiri::XML::NodeSet] node_set the titleInfo elements in the parallel grouping
        def parallel(node_set)
          display_types = !node_set.all? { |node| node['type'] == 'translated' }
          { parallelValue: simple_or_structured(node_set, display_types: display_types) }.tap do |result|
            # If none of these nodes are marked as primary, set the type to parallel
            unless node_set.any? { |node| node['usage'] }
              result[:type] = 'parallel'
              result[:status] = 'primary'
            end
          end
        end

        def simple_or_structured(node_set, display_types: true)
          node_set.map { |node| title_info_to_simple_or_structured(node, display_types: display_types) }
        end

        # @param [Nokogiri::XML::Element] title_info the titleInfo node
        def title_info_to_simple_or_structured(title_info, display_types:)
          # Find all the child nodes that have text
          children = title_info.xpath('./*[child::node()[self::text()]]')
          raise Mapper::MissingTitle if children.empty?

          # Is this a basic title or a title with parts
          return simple_value(title_info, display_types: display_types) if children.map(&:name) == ['title']

          with_attributes({ structuredValue: structured_value(children) }, title_info, display_types: display_types)
        end

        # @param [Nokogiri::XML::Element] node the titleInfo node
        # @param [Bool] display_types this is set to false in the case that it's a parallelValue and all are translations
        def simple_value(node, display_types:)
          with_attributes({ value: node.xpath('./mods:title', mods: DESC_METADATA_NS).text }, node, display_types: display_types)
        end

        # @param [Hash<Symbol,String>] value
        # @param [Nokogiri::XML::Element] title_info the titleInfo node
        # @param [Bool] display_types this is set to false in the case that it's a parallelValue and all are translations
        def with_attributes(value, title_info, display_types: true)
          value.tap do |result|
            result[:status] = 'primary' if title_info['usage'] == 'primary'
            result[:type] = title_info['type'] if display_types && title_info['type']
            result[:type] = 'transliterated' if title_info['transliteration']
            result[:language] = [language(title_info)] if title_info['lang']
            result[:standard] = { value: title_info['transliteration'] } if title_info['transliteration']
          end
        end

        def language(title_info)
          { code: title_info['lang'], source: { code: 'iso639-2b' } }.tap do |result|
            result[:script] = { code: title_info['script'], source: { code: 'iso15924' } } if title_info['script']
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
