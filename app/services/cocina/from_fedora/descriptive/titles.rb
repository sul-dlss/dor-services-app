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
          # Basic title: only subelement of titleInfo is title and no titleInfo type attribute
          # Filtering out text node children of titleInfo and the children that themselves have no text.
          child_nodes = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]/child::node()[not(self::text())][child::node()[self::text()]]', mods: DESC_METADATA_NS)
          return [{ value: child_nodes.first.text }] if child_nodes.map(&:name) == ['title']

          # Title with parts: multiple subelements in titleInfo
          # Filtering out text node children of titleInfo and the children that themselves have no text.
          child_nodes = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]/child::node()[not(self::text())][child::node()[self::text()]]', mods: DESC_METADATA_NS)
          return [{ structuredValue: structured_value(child_nodes) }] if child_nodes.any?

          raise Mapper::MissingTitle
        end

        private

        attr_reader :ng_xml

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
