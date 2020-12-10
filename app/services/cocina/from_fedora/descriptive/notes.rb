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
          abstract + simple_notes + parallel_notes + table_of_contents + parallel_table_of_contents + target_audience
        end

        private

        attr_reader :resource_element

        def abstract
          set = resource_element.xpath('mods:abstract', mods: DESC_METADATA_NS)
          set.map do |node|
            {
              type: 'summary',
              value: node.content,
              displayLabel: node[:displayLabel]
            }.compact
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

        def note_for(node)
          {
            value: node.text,
            type: node[:type],
            displayLabel: node[:displayLabel]
          }.tap do |attributes|
            value_language = LanguageScript.build(node: node)
            attributes[:valueLanguage] = value_language if value_language
          end.compact
        end

        def target_audience
          resource_element.xpath('mods:targetAudience', mods: DESC_METADATA_NS).map do |node|
            {
              type: 'target audience',
              value: node.content
            }.tap do |attrs|
              attrs[:source] = { code: node[:authority] } if node[:authority]
            end
          end.compact
        end

        def table_of_contents
          # Using all of the tocs that have no altRepGroup or only one instance with an altRepGroup id.
          toc_nodes = resource_element.xpath('mods:tableOfContents[not(@altRepGroup)]', mods: DESC_METADATA_NS).select { |node| node.text.present? } \
            + grouped_toc_nodes.select { |parallel_nodes| parallel_nodes.size == 1 }.map(&:first)
          toc_nodes.map { |note_node| toc_for(note_node).merge({ type: 'table of contents' }) }
        end

        def parallel_table_of_contents
          # Using all of the tocs that have at least two instances with an altRepGroup id.
          grouped_toc_nodes.reject { |parallel_toc_nodes| parallel_toc_nodes.size == 1 }.map { |parallel_toc_nodes| parallel_toc_for(parallel_toc_nodes) }
        end

        def grouped_toc_nodes
          @grouped_toc_nodes ||= begin
            toc_nodes = resource_element.xpath('mods:tableOfContents[@altRepGroup]', mods: DESC_METADATA_NS).select { |node| node.text.present? }
            toc_nodes.group_by { |node| node['altRepGroup'] }.values
          end
        end

        def parallel_toc_for(toc_nodes)
          {
            type: 'table of contents',
            parallelValue: toc_nodes.map { |toc_node| toc_for(toc_node) }
          }
        end

        def toc_for(node)
          {
            displayLabel: node[:displayLabel]
          }.tap do |attributes|
            value_language = LanguageScript.build(node: node)
            attributes[:valueLanguage] = value_language if value_language
            value_parts = node.content.split(' -- ')
            if value_parts.size == 1
              attributes[:value] = node.content
            else
              attributes[:structuredValue] = value_parts.map { |value_part| { value: value_part } }
            end
          end.compact
        end
      end
    end
  end
end
