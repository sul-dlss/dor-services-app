# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps contributors from cocina to MODS XML
      class Contributor
        # one way mapping:  MODS 'corporate' already maps to Cocina 'organization'
        NAME_TYPE = Cocina::FromFedora::Descriptive::Contributor::ROLES.invert.merge('event' => 'corporate').freeze
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
          Array(contributors).each do |contributor|
            next unless contributor.name

            xml.name name_attributes(contributor) do
              contributor.name.each do |name|
                write_structured(name) if name&.structuredValue
                if name&.value
                  name&.type == 'display' ? write_display_form(name) : write_basic(name)
                end
              end
              write_identifier(contributor) if contributor.identifier
              write_note(contributor) if contributor.note
              write_roles(contributor) if contributor.role
            end
          end
        end

        private

        attr_reader :xml, :contributors

        def name_attributes(contributor)
          { type: NAME_TYPE[contributor.type] }.tap do |attributes|
            attributes[:usage] = 'primary' if contributor.status == 'primary'
            value_uri = contributor.name.first&.uri
            if value_uri
              attributes[:valueURI] = value_uri
              source = contributor.name.first&.source
              attributes[:authority] = source.code if source&.code
              attributes[:authorityURI] = source.uri if source&.uri
            end
          end.compact
        end

        # return marcrelator roles only if any are present, otherwise return other roles
        def write_roles(contributor)
          mr_roles_xml = marcrelator_roles_xml(contributor)
          return mr_roles_xml if mr_roles_xml.present?

          contributor.role.each { |role| xml_role(role) unless role.value&.match?(/conference/i) }
        end

        MARC_RELATOR_PIECE = 'id.loc.gov/vocabulary/relators'

        def marcrelator_roles_xml(contributor)
          result = []
          contributor.role.each do |role|
            next unless role.source&.code == 'marcrelator' ||
                        role.source&.uri&.include?(MARC_RELATOR_PIECE) ||
                        role.uri&.include?(MARC_RELATOR_PIECE)

            result << xml_role(role)
          end
          result
        end

        def xml_role(role)
          xml.role do
            attributes = {}
            attributes[:valueURI] = role.uri if role.uri
            attributes[:authority] = role.source.code if role.source&.code
            attributes[:authorityURI] = role.source.uri if role.source&.uri
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
              Honeybadger.notify('[DATA ERROR] Unknown contributor note type', { tags: 'data_error' })
            end
          end
        end

        def write_identifier(contributor)
          contributor.identifier.each do |identifier|
            id_attributes = {
              displayLabel: identifier.displayLabel,
              type: identifier.uri ? 'uri' : FromFedora::Descriptive::IdentifierType.mods_type_for_cocina_type(identifier.type)
            }.tap do |attrs|
              attrs[:invalid] = 'yes' if identifier.status == 'invalid'
            end.compact
            xml.nameIdentifier identifier.value || identifier.uri, id_attributes
          end
        end

        def write_display_form(name)
          xml.displayForm name.value if name.type == 'display'
        end
      end
    end
  end
end
