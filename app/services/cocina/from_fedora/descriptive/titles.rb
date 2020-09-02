# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps titles
      class Titles
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

          raise Mapper::MissingTitle
        end

        private

        attr_reader :ng_xml
      end
    end
  end
end
