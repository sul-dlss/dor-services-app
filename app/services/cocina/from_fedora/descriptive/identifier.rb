# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS identifer to cocina identifier
      class Identifier
        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          identifiers.map do |id|
            { value: id.text }.tap do |item|
              item[:type] = id['type'].upcase if id['type']
              item[:displayLabel] = id['displayLabel'] if id['displayLabel']
            end
          end
        end

        private

        attr_reader :ng_xml

        def identifiers
          ng_xml.xpath('//mods:mods/mods:identifier', mods: DESC_METADATA_NS)
        end
      end
    end
  end
end
