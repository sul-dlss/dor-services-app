# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Descriptive objects from Fedora objects
    class Descriptive
      DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS
      DUBLIN_CORE_NS = 'http://purl.org/dc/elements/1.1/'

      BUILDERS = {
        note: Notes,
        language: Language,
        contributor: Contributor,
        event: Descriptive::Event,
        subject: Subject,
        form: Form,
        identifier: Identifier,
        adminMetadata: AdminMetadata,
        relatedResource: RelatedResource
      }.freeze

      # @param [#build] title_builder
      # @param [Nokogiri::XML] mods
      # @return [Hash] a hash that can be mapped to a cocina administrative model
      # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
      def self.props(mods:, title_builder: Titles)
        new(title_builder: title_builder, mods: mods).props
      end

      def initialize(title_builder:, mods:)
        @title_builder = title_builder
        @ng_xml = mods
      end

      def props
        add_descriptive_elements({ title: title_builder.build(ng_xml) })
      end

      private

      attr_reader :title_builder, :ng_xml

      def add_descriptive_elements(cocina_description)
        BUILDERS.each do |descriptive_property, builder|
          result = builder.build(ng_xml)
          cocina_description.merge!(descriptive_property => result) if result.present?
        end
        cocina_description
      end
    end
  end
end
