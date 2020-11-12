# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps notes
      class Notes
        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          abstract + notes
        end

        private

        attr_reader :ng_xml

        def abstract
          set = ng_xml.xpath('//mods:abstract', mods: DESC_METADATA_NS)
          set.map do |val|
            { type: 'summary', value: val.content }
          end
        end

        def notes
          set = ng_xml.xpath('//mods:note', mods: DESC_METADATA_NS).select { |node| node.text.present? }
          set.map do |node|
            { value: node.text }.tap do |attributes|
              attributes[:type] = node[:type] if node[:type]
              attributes[:displayLabel] = node[:displayLabel] if node[:displayLabel]
            end
          end
        end
      end
    end
  end
end
