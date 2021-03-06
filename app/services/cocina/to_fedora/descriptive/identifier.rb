# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps identifiers from cocina to MODS XML
      class Identifier
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] identifiers
        # @params [IdGenerator] id_generator
        def self.write(xml:, identifiers:, id_generator:)
          new(xml: xml, identifiers: identifiers, id_generator: id_generator).write
        end

        def initialize(xml:, identifiers:, id_generator:)
          @xml = xml
          @identifiers = identifiers
          @id_generator = id_generator
        end

        def write
          Array(identifiers).each do |identifier|
            if identifier.parallelValue
              write_parallel(identifier)
            else
              write_identifier(identifier)
            end
          end
        end

        private

        attr_reader :xml, :identifiers, :id_generator

        def write_parallel(parallel_identifier)
          altrepgroup_id = id_generator.next_altrepgroup
          parallel_identifier.parallelValue.each { |identifier| write_identifier(identifier, altrepgroup_id: altrepgroup_id) }
        end

        def write_identifier(identifier, altrepgroup_id: nil)
          id_attributes = {
            displayLabel: identifier.displayLabel,
            type: identifier.uri ? 'uri' : FromFedora::Descriptive::IdentifierType.mods_type_for_cocina_type(identifier.type),
            altRepGroup: altrepgroup_id
          }.tap do |attrs|
            attrs[:invalid] = 'yes' if identifier.status == 'invalid'
          end.compact
          xml.identifier identifier.value || identifier.uri, id_attributes
        end
      end
    end
  end
end
