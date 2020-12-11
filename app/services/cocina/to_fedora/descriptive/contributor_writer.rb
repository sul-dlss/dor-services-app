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
            parallel_values.each_with_index { |parallel_value, index| write_parallel_contributor(contributor, contributor.name.first, parallel_value, index, altrepgroup_id) }
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

        def write_parallel_contributor(contributor, name, parallel_name, parallel_index, altrepgroup_id)
          attributes = parallel_name_attributes(name, parallel_name, name_title_group_indexes.dig(0, parallel_index), altrepgroup_id)
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
          # rubocop doesn't like safe navigation here either and this code is clearer.
          # rubocop:disable Style/SafeNavigation
          return {} if parallel_name.value && parallel_name.value.blank?

          # rubocop:enable Style/SafeNavigation

          {
            type: NAME_TYPE.fetch(name.type, name_title_group ? 'personal' : nil),
            nameTitleGroup: name_title_group,
            altRepGroup: altrepgroup_id,
            script: parallel_name.valueLanguage&.valueScript&.code
          }.tap do |attributes|
            attributes[:usage] = 'primary' if parallel_name.status == 'primary'
            value_uri = parallel_name.uri
            if value_uri
              attributes[:valueURI] = value_uri
              attributes[:authority] = parallel_name.source&.code
              attributes[:authorityURI] = parallel_name.source&.uri
            end
            attributes[:transliteration] = parallel_name.standard&.value if parallel_name.type == 'transliteration'
          end.compact
        end

        def name_attributes(contributor, name, name_title_group)
          # rubocop doesn't like safe navigation here either and this code is clearer.
          # rubocop:disable Style/SafeNavigation
          return {} if name.value && name.value.blank?

          # rubocop:enable Style/SafeNavigation

          {
            type: NAME_TYPE.fetch(contributor.type, name_title_group ? 'personal' : nil),
            nameTitleGroup: name_title_group,
            script: name.valueLanguage&.valueScript&.code
          }.tap do |attributes|
            attributes[:usage] = 'primary' if contributor.status == 'primary' || name.status == 'primary'
            value_uri = name.uri
            if value_uri
              attributes[:valueURI] = value_uri
              attributes[:authority] = name.source&.code
              attributes[:authorityURI] = name.source&.uri
            end
          end.compact
        end

        def write_roles(contributor)
          Array(contributor.role).reject { |role| filtered_role?(role, contributor.type) }.each do |role|
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
          {}.tap do |attributes|
            attributes[:type] = NAME_PART[part.type] if part.type
          end.compact
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
