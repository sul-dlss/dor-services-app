# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps titles
      class Titles
        def self.build(item)
          new(item).build
        end

        def initialize(item)
          @item = item
        end

        def build
          return [{ value: item.properties.title.first }] if item.is_a? Dor::Etd

          # Some hydrus items don't have titles, so using label. See https://github.com/sul-dlss/hydrus/issues/421
          return [{ value: 'Hydrus' }] if item.label == 'Hydrus'

          # Basic title: only subelement of titleInfo is title and no titleInfo type attribute
          # Filtering out text node children of titleInfo and the children that themselves have no text.
          child_nodes = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]/child::node()[not(self::text())][child::node()[self::text()]]', mods: DESC_METADATA_NS)
          return [{ value: child_nodes.first.text }] if child_nodes.map(&:name) == ['title']

          raise Mapper::MissingTitle
        end

        private

        attr_reader :item

        def ng_xml
          item.descMetadata.ng_xml
        end
      end
    end
  end
end
