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
            attributes = {}
            attributes[:type] = identifier.type.downcase if identifier.type
            attributes[:displayLabel] = identifier.displayLabel if identifier.displayLabel
            xml.identifier identifier.value, attributes
          end
        end

        private

        attr_reader :xml, :identifiers
      end
    end
  end
end
