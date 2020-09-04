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
          title_infos = ng_xml.xpath('//mods:mods/mods:titleInfo', mods: DESC_METADATA_NS)
          title_infos.map do |title_info|
            # Find all the child nodes that have text
            children = title_info.xpath('./*[child::node()[self::text()]]')
            raise Mapper::MissingTitle if children.empty?

            # Is this a basic title or a title with parts
            children.map(&:name) == ['title'] ? simple_value(title_info) : { structuredValue: structured_value(children) }
          end
        end

        private

        attr_reader :ng_xml

        # @param [Nokogiri::XML::Element] node the titleInfo node
        def simple_value(node)
          { value: node.xpath('./mods:title', mods: DESC_METADATA_NS).text }.tap do |h|
            h[:status] = 'primary' if node['usage'] == 'primary'
            h[:type] = node['type'] if node['type']
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
