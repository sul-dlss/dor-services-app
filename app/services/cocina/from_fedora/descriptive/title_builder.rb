# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps titles
      class TitleBuilder
        # @param [Nokogiri::XML::Element] title_info_element titleInfo element
        # @param [Cocina::FromFedora::DataErrorNotifier] notifier
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(title_info_element:, notifier:)
          new(title_info_element: title_info_element, notifier: notifier).build
        end

        def initialize(title_info_element:, notifier:)
          @title_info_element = title_info_element
          @notifier = notifier
        end

        def build
          # Find all the child nodes that have text
          return nil if title_info_element.children.empty?

          children = title_info_element.xpath('./*[child::node()[self::text()]]')
          if children.empty?
            notifier.warn('Empty title node')
            return nil
          end

          notifier.warn('Title with type') if children_with_type?(children)

          # If a displayLabel only with no title text element
          # Note: this is an error condition,
          # exceptions documented at: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_value_dependencies.txt
          return {} if children.map(&:name) == []

          # Is this a basic title or a title with parts
          return simple_value(title_info_element) if simple_title?(children)

          { structuredValue: structured_value(children, title_info_element['type']), note: note(children) }.compact
        end

        private

        attr_reader :title_info_element, :notifier

        def children_with_type?(children)
          children.any? do |child|
            child.name == 'title' && child[:type].present?
          end
        end

        def simple_title?(children)
          children.size == 1 && children.first.name == 'title'
        end

        # @param [Nokogiri::XML::Element] node the titleInfo node
        def simple_value(node)
          value = node.xpath('./mods:title', mods: DESC_METADATA_NS).text

          { value: clean_title(value, node['type'], node.name) }
        end

        # @param [Nokogiri::XML::NodeSet] child_nodes the children of the titleInfo
        def structured_value(child_nodes, type)
          child_nodes.map do |node|
            { value: clean_title(node.text, type, node.name), type: Titles::TYPES[node.name] }
          end
        end

        def clean_title(title, type, tag)
          if %w[title titleInfo].include?(tag)
            if type == 'abbreviated'
              title.delete_suffix(',')
            else
              title.delete_suffix(',').delete_suffix('.')
            end
          elsif tag == 'nonSort'
            title.delete_suffix(' ')
          else
            title
          end
        end

        def note(child_nodes)
          unsortable = child_nodes.select { |node| node.name == 'nonSort' }
          return nil if unsortable.empty?

          count = unsortable.sum do |node|
            last_character = node.text.slice(-1, 1)
            add = ['-', "'", ' '].include?(last_character) ? 0 : 1
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
