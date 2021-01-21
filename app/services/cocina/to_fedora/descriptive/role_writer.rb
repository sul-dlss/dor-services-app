# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps roles from cocina to MODS XML
      class RoleWriter
        # @params [Nokogiri::XML::Builder] xml
        # @params [Cocina::Models::DescriptiveValue] role
        def self.write(xml:, role:)
          new(xml: xml, role: role).write
        end

        def initialize(xml:, role:)
          @xml = xml
          @role = role
        end

        def write
          xml.role do
            attributes = {
              valueURI: role.uri,
              authority: role.source&.code,
              authorityURI: role.source&.uri
            }.compact
            if role.value.present?
              attributes[:type] = 'text'
              xml.roleTerm role.value, attributes
            end
            if role.code.present?
              attributes[:type] = 'code'
              xml.roleTerm role.code, attributes
            end
          end
        end

        private

        attr_reader :xml, :role
      end
    end
  end
end
