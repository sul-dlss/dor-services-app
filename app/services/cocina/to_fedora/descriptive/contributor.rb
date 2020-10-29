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
            xml.name name_attributes(contributor) do
              contributor.name.each do |name|
                write_structured(name) if name&.structuredValue
                if name&.value
                  name&.type == 'display' ? write_display_form(name) : write_basic(name)
                end
              end
              write_identifier(contributor) if contributor&.identifier
              write_note(contributor) if contributor&.note
              write_roles(contributor) if contributor&.role
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

        def write_roles(contributor)
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

        def write_basic(name)
          xml.namePart name.value
        end

        def name_part_attributes(part)
          {}.tap do |attributes|
            attributes[:type] = NAME_PART.fetch(part.type) if part.type
          end
        end

        def write_structured(name)
          Array(name.structuredValue).each do |part|
            xml.namePart part.value, name_part_attributes(part)
          end
        end

        def write_note(contributor)
          contributor.note.each do |note|
            case note.type
            when 'affiliation'
              xml.affiliation note.value
            when 'description'
              xml.description note.value
            else
              Honeybadger.notify('Notice: Unknown contributor note type')
            end
          end
        end

        def write_identifier(contributor)
          contributor.identifier.each do |ident|
            xml.nameIdentifier ident.value, type: ident.source.code
          end
        end

        def write_display_form(name)
          xml.displayForm name.value if name.type == 'display'
        end
      end
    end
  end
end
