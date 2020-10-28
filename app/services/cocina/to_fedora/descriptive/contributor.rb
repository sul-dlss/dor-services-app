# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps contributors from cocina to MODS XML
      class Contributor
        NAME_TYPE = FromFedora::Descriptive::Contributor::ROLES.invert.freeze
        NAME_PART = FromFedora::Descriptive::Contributor::NAME_PART.invert.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::Contributor>] contributors
        def self.write(xml:, contributors:)
          new(xml: xml, contributors: contributors).write
        end

        def initialize(xml:, contributors:)
          @xml = xml
          @contributors = contributors
        end

        def write
          Array(contributors).each_with_index do |contributor, _alt_rep_group|
            if contributor.name.count == 1 && contributor.name.first.structuredValue.nil?
              write_basic(contributor)
            else
              write_complex(contributor)
            end
          end
        end

        private

        attr_reader :xml, :contributors

        def name_attributes(contributor)
          return {} if contributor.type.nil?

          { type: NAME_TYPE.fetch(contributor.type) }.tap do |attributes|
            attributes[:usage] = 'primary' if contributor.status == 'primary'
          end
        end

        def write_basic(contributor)
          xml.name name_attributes(contributor) do
            xml.namePart contributor.name.first.value
            write_roles_for(contributor)
          end
        end

        def write_roles_for(contributor)
          Array(contributor.role).each do |role|
            xml.role do
              attributes = {}
              if role.value.present?
                attributes[:type] = 'text'
                value = role.value
              elsif role.code.present?
                attributes[:type] = 'code'
                value = role.code
              end
              attributes[:valueURI] = role.uri if role.uri
              attributes[:authority] = role.source.code if role.source&.code
              attributes[:authorityURI] = role.source.uri if role.source&.uri
              xml.roleTerm value, attributes if value
            end
          end
        end

        def write_complex(contributor)
          xml.name name_attributes(contributor) do
            contributor.name.each do |name|
              Array(name.structuredValue).each do |name_part|
                write_structured_name_part(name_part)
              end

              xml.displayForm name.value if name.type == 'display'
            end
            Array(contributor.note).each do |note|
              case note.type
              when 'affiliation'
                xml.affiliation note.value
              when 'description'
                xml.description note.value
              else
                raise "Unknown contributor note type #{note.type}"
              end
            end

            Array(contributor.identifier).each do |ident|
              xml.nameIdentifier ident.value, type: ident.source.code
            end
          end
        end

        def write_structured_name_part(name_part_structured_value)
          attrib = {}
          attrib[:type] = NAME_PART.fetch(name_part_structured_value.type) if name_part_structured_value.type
          xml.namePart name_part_structured_value.value, attrib
        end
      end
    end
  end
end
