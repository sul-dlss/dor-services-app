# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Builds cocina identifier
      class IdentifierBuilder
        # @param [Nokogiri::XML::Element] identifier_element identifier element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build_from_identifier(identifier_element:)
          new(identifier_element: identifier_element, type: identifier_element[:type]).build
        end

        # @param [Nokogiri::XML::Element] identifier_element recordIdentifier element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build_from_record_identifier(identifier_element:)
          new(identifier_element: identifier_element, type: identifier_element[:source]).build
        end

        # @param [Nokogiri::XML::Element] identifier_element nameIdentifier element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build_from_name_identifier(identifier_element:)
          new(identifier_element: identifier_element, type: identifier_element[:type]).build
        end

        def initialize(identifier_element:, type:)
          @identifier_element = identifier_element
          @with_note = with_note
          @cocina_type, @mods_type, = types_for(type)
        end

        def build
          return if identifier_element.text.blank? && identifier_element.attributes.size.zero?

          {
            displayLabel: identifier_element['displayLabel']
          }.tap do |attrs|
            if cocina_type == 'uri'
              attrs[:uri] = identifier_element.text
            else
              attrs[:type] = cocina_type
              attrs[:value] = identifier_element.text
              attrs[:source] = build_source
            end
            attrs[:status] = 'invalid' if identifier_element['invalid'] == 'yes'
          end.compact
        end

        private

        attr_reader :identifier_element, :with_note, :cocina_type, :mods_type

        def types_for(type)
          return ['uri', 'uri', IdentifierType::STANDARD_IDENTIFIER_SCHEMES] if type == 'uri'

          IdentifierType.cocina_type_for_mods_type(type)
        end

        def build_source
          {
            uri: identifier_element['typeURI']
          }.tap do |props|
            props[:code] = mods_type unless props[:uri]
          end.compact.presence
        end
      end
    end
  end
end
