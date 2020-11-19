# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Descriptive objects from Fedora objects
    class Descriptive
      DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

      # @param [#build] title_builder
      # @param [Nokogiri::XML] mods
      # @return [Hash] a hash that can be mapped to a cocina descriptive model
      # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
      def self.props(mods:, title_builder: Titles)
        new(title_builder: title_builder, mods: mods).props
      end

      def initialize(title_builder:, mods:)
        @title_builder = title_builder
        @ng_xml = mods
      end

      def props
        DescriptiveBuilder.build(title_builder: @title_builder, resource_element: @ng_xml.root)
      end
    end
  end
end
