# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps contributor from cocina to MODS XML
      class ContributorWriter
        # one way mapping:  MODS 'corporate' already maps to Cocina 'organization'
        NAME_TYPE = Cocina::FromFedora::Descriptive::Contributor::ROLES.invert.merge('event' => 'corporate').freeze
        NAME_PART = FromFedora::Descriptive::Contributor::NAME_PART.invert.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Cocina::Models::Contributor] contributor
        # @params [IdGenerator] id_generator
        # @params [String] name_title_group_indexes
        def self.write(xml:, contributor:, id_generator:, name_title_group_indexes: {})
          new(xml: xml, contributor: contributor, id_generator: id_generator, name_title_group_indexes: name_title_group_indexes).write
        end

        def initialize(xml:, contributor:, id_generator:, name_title_group_indexes: {})
          @xml = xml
          @contributor = contributor
          @id_generator = id_generator
          @name_title_group_indexes = name_title_group_indexes
        end

        def write
          return unless contributor.name

          parallel_values = contributor.name.first.parallelValue
          if parallel_values
            altrepgroup_id = id_generator.next_altrepgroup
            parallel_values.each_with_index do |parallel_value, index|
              name_title_group = name_title_group_indexes.dig(0, index)
              write_parallel_contributor(contributor, contributor.name.first, parallel_value, name_title_group, altrepgroup_id)
            end
          else
            write_contributor(contributor)
          end
        end

        private

        attr_reader :xml, :contributor, :name_title_group_indexes, :id_generator

        def write_contributor(contributor)
          xml.name name_attributes(contributor, contributor.name.first, name_title_group_indexes[0]) do
            contributor.name.each do |name|
              write_structured(name) if name.structuredValue
              if name.value
                name.type == 'display' ? write_display_form(name) : write_basic(name)
              end
            end
            write_identifier(contributor) if contributor.identifier
            write_note(contributor)
            write_roles(contributor)
          end
        end

        def write_parallel_contributor(contributor, name, parallel_name, name_title_group, altrepgroup_id)
          attributes = parallel_name_attributes(name, parallel_name, name_title_group, altrepgroup_id)
          xml.name attributes do
            if parallel_name.structuredValue
              write_structured(parallel_name)
            else
              write_basic(parallel_name)
            end
            write_identifier(contributor) if contributor.identifier
            write_note(contributor)
            write_roles(contributor)
          end
        end

        def parallel_name_attributes(name, parallel_name, name_title_group, altrepgroup_id)
          {
            type: NAME_TYPE.fetch(name.type, name_title_group ? 'personal' : nil),
            nameTitleGroup: name_title_group,
            altRepGroup: altrepgroup_id,
            lang: parallel_name.valueLanguage&.code,
            script: parallel_name.valueLanguage&.valueScript&.code,
            authority: parallel_name.source&.code,
            valueURI: parallel_name.uri,
            authorityURI: parallel_name.source&.uri
          }.tap do |attributes|
            attributes[:usage] = 'primary' if parallel_name.status == 'primary'
            attributes[:transliteration] = parallel_name.standard&.value if parallel_name.type == 'transliteration'
            attributes['xlink:href'] = name.valueAt
          end.compact
        end

        def name_attributes(contributor, name, name_title_group)
          {
            type: NAME_TYPE.fetch(contributor.type, name_title_group ? 'personal' : nil),
            nameTitleGroup: name_title_group,
            script: name.valueLanguage&.valueScript&.code,
            valueURI: name.uri,
            authority: name.source&.code,
            authorityURI: name.source&.uri,
            displayLabel: name.displayLabel
          }.tap do |attributes|
            attributes[:usage] = 'primary' if contributor.status == 'primary'
            attributes['xlink:href'] = name.valueAt
          end.compact
        end

        def write_roles(contributor)
          Array(contributor.role).reject { |role| filtered_role?(role, contributor.type) }.each do |role|
            RoleWriter.write(xml: xml, role: role)
          end
        end

        def filtered_role?(role, contributor_type)
          return true if role.value&.match?(/conference/i)
          return true if [
            'Stanford self-deposit contributor types',
            'DataCite contributor types',
            'DataCite properties'
          ].include?(role.source&.value) && Cocina::FromFedora::Descriptive::Contributor::ROLES.values.include?(contributor_type)

          false
        end

        def write_basic(name)
          xml.namePart name.value
        end

        def name_part_attributes(part)
          {
            type: NAME_PART[part.type]
          }.compact
        end

        def write_structured(name)
          Array(name.structuredValue).each do |part|
            xml.namePart part.value, name_part_attributes(part)
          end
        end

        def write_note(contributor)
          Array(contributor.note).each do |note|
            case note.type
            when 'affiliation'
              xml.affiliation note.value
            when 'description'
              xml.description note.value
            else
              # This should not happen, as mapping code only produces affiliation and description.
              raise 'Unknown contributor note type'
            end
          end
        end

        def write_identifier(contributor)
          contributor.identifier.each do |identifier|
            id_attributes = {
              displayLabel: identifier.displayLabel,
              type: FromFedora::Descriptive::IdentifierType.mods_type_for_cocina_type(identifier.type)
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
