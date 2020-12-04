# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps notes
      class Notes
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder: nil)
          new(resource_element: resource_element).build
        end

        def initialize(resource_element:)
          @resource_element = resource_element
        end

        def build
          abstract + simple_notes + parallel_notes + table_of_contents
        end

        private

        attr_reader :resource_element

        def abstract
          set = resource_element.xpath('mods:abstract', mods: DESC_METADATA_NS)
          set.map do |node|
            { type: 'summary', value: node.content }.tap do |attributes|
              attributes[:displayLabel] = node[:displayLabel] if node[:displayLabel]
            end
          end
        end

        def simple_notes
          # Using all of the notes that have no altRepGroup or only one instance with an altRepGroup id.
          note_nodes = resource_element.xpath('mods:note[not(@altRepGroup)]', mods: DESC_METADATA_NS).select { |node| node.text.present? } \
            + grouped_note_nodes.select { |parallel_note_nodes| parallel_note_nodes.size == 1 }.map(&:first)
          note_nodes.map { |note_node| note_for(note_node) }
        end

        def parallel_notes
          # Using all of the notes that have at least two instances with an altRepGroup id.
          grouped_note_nodes.reject { |parallel_note_nodes| parallel_note_nodes.size == 1 }.map { |parallel_note_nodes| parallel_note_for(parallel_note_nodes) }
        end

        def grouped_note_nodes
          @grouped_note_nodes ||= begin
            note_nodes = resource_element.xpath('mods:note[@altRepGroup]', mods: DESC_METADATA_NS).select { |node| node.text.present? }
            note_nodes.group_by { |node| node['altRepGroup'] }.values
          end
        end

        def parallel_note_for(note_nodes)
          {
            parallelValue: note_nodes.map { |note_node| note_for(note_node) }
          }
        end

        def note_for(note_node)
          { value: note_node.text }.tap do |attributes|
            attributes[:type] = note_node[:type]
            attributes[:displayLabel] = note_node[:displayLabel]
            attributes[:valueLanguage] = value_language_for(note_node)
          end.compact
        end

        def value_language_for(note_node)
          value_language_attrs = {}.tap do |attrs|
            if note_node[:lang].present?
              attrs[:code] = note_node[:lang]
              attrs[:source] = { code: 'iso639-2b' }
            end
            if note_node[:script].present?
              attrs[:valueScript] = {
                "code": note_node[:script],
                "source": {
                  "code": 'iso15924'
                }
              }
            end
          end
          value_language_attrs.empty? ? nil : value_language_attrs
        end

        def table_of_contents
          set = resource_element.xpath('mods:tableOfContents', mods: DESC_METADATA_NS)
          set.map do |node|
            { type: 'table of contents' }.tap do |attributes|
              attributes[:displayLabel] = node[:displayLabel] if node[:displayLabel]
              value_parts = node.content.split(' -- ')
              if value_parts.size == 1
                attributes[:value] = node.content
              else
                attributes[:structuredValue] = value_parts.map { |value_part| { value: value_part } }
              end
            end
          end
        end
      end
    end
  end
end
