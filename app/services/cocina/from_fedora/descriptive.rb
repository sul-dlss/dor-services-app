# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Descriptive objects from Fedora objects
    class Descriptive
      DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

      BUILDERS = {
        note: Notes,
        language: Language,
        contributor: Contributor,
        event: Descriptive::Event,
        subject: Subject,
        form: Form,
        identifier: Identifier,
        adminMetadata: AdminMetadata,
        relatedResource: RelatedResource,
        classification: Classification
      }.freeze

      # @param [Dor::Item,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina administrative model
      # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @label = item.label
        @ng_xml = item.descMetadata.ng_xml
      end

      def props
        titles = if label == 'Hydrus'
                   # Some hydrus items don't have titles, so using label. See https://github.com/sul-dlss/hydrus/issues/421
                   [{ value: 'Hydrus' }]
                 else
                   Titles.build(ng_xml)
                 end
        add_descriptive_elements(title: titles)
      end

      private

      attr_reader :label, :ng_xml

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
