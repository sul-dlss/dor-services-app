# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Creates Cocina Descriptive objects from MODS resource element.
      class DescriptiveBuilder
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
          geographic: Geographic
        }.freeze

        # @param [#build] title_builder
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @return [Hash] a hash that can be mapped to a cocina descriptive model
        # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
        def self.build(resource_element:, title_builder: Titles)
          new(title_builder: title_builder).build(resource_element: resource_element)
        end

        def initialize(title_builder: Titles)
          @title_builder = title_builder
        end

        def build(resource_element:, require_title: true, omit_builders: [])
          cocina_description = {}
          title_result = @title_builder.build(resource_element: resource_element, require_title: require_title)
          cocina_description[:title] = title_result if title_result.present?

          BUILDERS.each do |descriptive_property, builder|
            # This is a temporary fix pending https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/138
            # and https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/162
            next if omit_builders.include?(descriptive_property)

            result = builder.build(resource_element: resource_element, descriptive_builder: self)
            cocina_description.merge!(descriptive_property => result) if result.present?
          end
          cocina_description
        end
      end
    end
  end
end
