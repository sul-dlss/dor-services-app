# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps subject nodes from MODS to cocina
      class Subject
        NODE_TYPE = {
          'temporal' => 'time',
          'topic' => 'topic'
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
          subjects.map do |subject|
            node_set = subject.xpath('*')
            case node_set.size
            when 1
              attrs = {}
              if subject[:authority]
                attrs[:source] = { code: subject[:authority], uri: subject[:authorityURI] }
                attrs[:uri] = subject[:valueURI]
              end
              simple_item(node_set.first, attrs)
            else
              structured_value(node_set)
            end
          end
        end

        private

        attr_reader :ng_xml

        def structured_value(node_set)
          values = node_set.map { |node| simple_item(node) }
          { structuredValue: values }
        end

        def simple_item(node, attrs = {})
          if node[:authority]
            attrs[:source] = { code: node[:authority], uri: node[:authorityURI] }
            attrs[:uri] = node[:valueURI]
          end
          attrs.merge(value: node.text, type: NODE_TYPE.fetch(node.name))
        end

        def subjects
          ng_xml.xpath('//mods:subject', mods: DESC_METADATA_NS)
        end
      end
    end
  end
end
