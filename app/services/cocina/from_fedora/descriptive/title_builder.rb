# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps titles
      class TitleBuilder
        # @param [Nokogiri::XML::Element] title_info_element titleInfo element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(title_info_element:)
          new(title_info_element: title_info_element).build
        end

        def initialize(title_info_element:)
          @title_info_element = title_info_element
        end

        def build
          # Find all the child nodes that have text
          return nil if title_info_element.children.empty?

          children = title_info_element.xpath('./*[child::node()[self::text()]]')
          if children.empty?
            Honeybadger.notify('[DATA ERROR] Empty title node', { tags: 'data_error' })
            return nil
          end

          # If a displayLabel only with no title text element
          # Note: this is an error condition,
          # exceptions documented at: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_value_dependencies.txt
          return {} if children.map(&:name) == []

          # Is this a basic title or a title with parts
          return simple_value(title_info_element) if simple_title?(children)

          { structuredValue: structured_value(children), note: note(children) }.compact
        end

        private

        attr_reader :title_info_element

        def simple_title?(children)
          return false if children.map(&:name) != ['title'] || children.size > 1

          # There is only one child and it's a title element. If it has the
          # @type attr set, it should not be treated as a simple value
          children.first[:type].nil?
        end

        # @param [Nokogiri::XML::Element] node the titleInfo node
        def simple_value(node)
          value = node.xpath('./mods:title', mods: DESC_METADATA_NS).text

          { value: value }
        end

        # @param [Nokogiri::XML::NodeSet] child_nodes the children of the titleInfo
        def structured_value(child_nodes)
          child_nodes.map do |node|
            { value: node.text, type: Titles::TYPES[node.name] }
          end
        end

        def note(child_nodes)
          unsortable = child_nodes.select { |node| node.name == 'nonSort' }
          return nil if unsortable.empty?

          count = unsortable.sum do |node|
            add = node.text.end_with?('-') || node.text.end_with?("'") ? 0 : 1
            node.text.size + add
          end
          [{
            "value": count.to_s,  # cast to String until cocina-models 0.40.0 is used. See https://github.com/sul-dlss/cocina-models/pull/146
            "type": 'nonsorting character count'
          }]
        end
      end
    end
  end
end
