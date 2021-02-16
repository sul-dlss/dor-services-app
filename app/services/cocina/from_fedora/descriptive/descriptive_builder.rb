# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Creates Cocina Descriptive objects from MODS resource element.
      class DescriptiveBuilder
        attr_reader :notifier

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
          geographic: Geographic,
          access: Descriptive::Access
        }.freeze

        # @param [#build] title_builder
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::DataErrorNotifier] notifier
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina descriptive model
        def self.build(resource_element:, notifier:, title_builder: Titles, purl: nil)
          new(title_builder: title_builder, notifier: notifier).build(resource_element: resource_element, purl: purl)
        end

        def initialize(notifier:, title_builder: Titles)
          @title_builder = title_builder
          @notifier = notifier
        end

        # @return [Hash] a hash that can be mapped to a cocina descriptive model
        def build(resource_element:, purl: nil, require_title: true)
          cocina_description = {}
          title_result = @title_builder.build(resource_element: resource_element, require_title: require_title, notifier: notifier)
          cocina_description[:title] = title_result if title_result.present?

          purl_value = purl || Purl.primary_purl_node(resource_element, purl)&.content&.presence
          cocina_description[:purl] = purl_value if purl_value

          BUILDERS.each do |descriptive_property, builder|
            result = builder.build(resource_element: resource_element, descriptive_builder: self, purl: purl_value)
            cocina_description.merge!(descriptive_property => result) if result.present?
          end
          cocina_description
        end
      end
    end
  end
end
