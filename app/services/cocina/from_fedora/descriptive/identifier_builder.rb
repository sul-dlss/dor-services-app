# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Builds cocina identifier
      class IdentifierBuilder
        # @param [Nokogiri::XML::Element] identifier_element identifier element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build_from_identifier(identifier_element:)
          new(identifier_element: identifier_element, type: identifier_element[:type], with_note: true).build
        end

        # @param [Nokogiri::XML::Element] identifier_element recordIdentifier element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build_from_record_identifier(identifier_element:)
          new(identifier_element: identifier_element, type: identifier_element[:source], with_note: false).build
        end

        # @param [Nokogiri::XML::Element] identifier_element nameIdentifier element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build_from_name_identifier(identifier_element:)
          new(identifier_element: identifier_element, type: identifier_element[:type], with_note: false).build
        end

        def initialize(identifier_element:, type:, with_note:)
          @identifier_element = identifier_element
          @with_note = with_note
          @cocina_type, @mods_type, @identifier_source = types_for(type)
        end

        def build
          {
            displayLabel: identifier_element['displayLabel']
          }.tap do |attrs|
            if cocina_type == 'uri'
              attrs[:uri] = identifier_element.text
            else
              attrs[:type] = cocina_type
              attrs[:value] = identifier_element.text
            end
            attrs[:status] = 'invalid' if identifier_element['invalid'] == 'yes'
            attrs[:note] = build_note if mods_type && with_note
          end.compact
        end

        private

        attr_reader :identifier_element, :with_note, :cocina_type, :mods_type, :identifier_source

        def types_for(type)
          return ['uri', 'uri', IdentifierType::STANDARD_IDENTIFIER_SCHEMES] if type == 'uri'

          IdentifierType.cocina_type_for_mods_type(type)
        end

        def build_note
          [
            {
              "type": 'type',
              "value": mods_type

            }.tap do |note_attrs|
              if identifier_source == IdentifierType::STANDARD_IDENTIFIER_SCHEMES
                note_attrs[:uri] = "http://id.loc.gov/vocabulary/identifiers/#{mods_type}"
                note_attrs[:source] = {
                  "value": 'Standard Identifier Schemes',
                  "uri": 'http://id.loc.gov/vocabulary/identifiers/'
                }
              elsif identifier_source == IdentifierType::STANDARD_IDENTIFIER_SOURCE_CODES
                note_attrs[:source] = { "value": 'Standard Identifier Source Codes' }
              end
            end
          ]
        end
      end
    end
  end
end
