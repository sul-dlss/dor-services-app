# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps identifiers from cocina to MODS XML
      class Identifier
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] identifiers
        def self.write(xml:, identifiers:)
          new(xml: xml, identifiers: identifiers).write
        end

        def initialize(xml:, identifiers:)
          @xml = xml
          @identifiers = identifiers
        end

        def write
          Array(identifiers).each do |identifier|
            id_attributes = {
              displayLabel: identifier.displayLabel,
              type: identifier.uri ? 'uri' : FromFedora::Descriptive::IdentifierType.mods_type_for_cocina_type(identifier.type)
            }.tap do |attrs|
              attrs[:invalid] = 'yes' if identifier.status == 'invalid'
            end.compact
            xml.identifier identifier.value || identifier.uri, id_attributes
          end
        end

        private

        attr_reader :xml, :identifiers
      end
    end
  end
end
