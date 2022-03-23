# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps contributor from cocina to MODS XML
      class ContributorWriter
        # one way mapping:  MODS 'corporate' already maps to Cocina 'organization'
        NAME_TYPE = Cocina::FromFedora::Descriptive::Contributor::ROLES.invert.freeze
        NAME_PART = FromFedora::Descriptive::Contributor::NAME_PART.invert.merge('activity dates' => 'date').freeze
        UNCITED_DESCRIPTION = 'not included in citation'

        # @params [Nokogiri::XML::Builder] xml
        # @params [Cocina::Models::Contributor] contributor
        # @params [IdGenerator] id_generator
        # @params [Hash<Hash, Hash<Hash, Integer>>] name_title_vals_index is a Hash
        #   the key is a hash representing a single contributor name, with a key of :value or :structuredValue
        #   the value is a hash, where
        #      the key is a hash representing a single title value, with a key of :value or :structuredValue
        #      the value is the nameTitleGroup number as an Integer
        #   e.g. {{:value=>"James Joyce"}=>{:value=>"Portrait of the artist as a young man"}=>1}
        def self.write(xml:, contributor:, id_generator:, name_title_vals_index: {})
          new(xml: xml, contributor: contributor, id_generator: id_generator, name_title_vals_index: name_title_vals_index).write
        end

        def initialize(xml:, contributor:, id_generator:, name_title_vals_index: {})
          @xml = xml
          @contributor = contributor
          @id_generator = id_generator
          @name_title_vals_index = name_title_vals_index
        end

        def write
          if contributor.type == 'unspecified others'
            write_etal
          elsif contributor.name.present?
            # we expect contributor to have a single value for name property
            contrib_name = contributor.name.first
            parallel_name_values = contrib_name.parallelValue
            if parallel_name_values.present?
              write_contributor_with_parallel_names(parallel_name_values, contrib_name)
            else
              write_contributor(contributor)
            end
          end
        end

        private

        attr_reader :xml, :contributor, :name_title_vals_index, :id_generator

        def write_etal
          xml.name do
            xml.etal
          end
        end

        def write_contributor(contributor)
          name_title_group = nil

          contrib_name_value_slices = NameTitleGroup.contrib_name_value_slices(contributor)
          contrib_name_value_slices.each do |contrib_name_value_slice|
            next if name_title_vals_index.blank?

            name_title_group = name_title_vals_index[contrib_name_value_slice]&.values&.first
          end

          attributes = name_attributes(contributor, contributor.name.first, name_title_group)
          type_attr = NAME_TYPE.fetch(contributor.type, name_title_group ? 'personal' : nil)
          attributes[:type] = type_attr if type_attr
          xml.name attributes do
            contributor.name.each do |name|
              write_name(name)
            end
            write_identifier(contributor) if contributor.identifier.present?
            write_note(contributor)
            write_roles(contributor)
            xml.etal if contributor.type == 'unspecified others'
          end
        end

        def write_name(name)
          if name.structuredValue.present?
            write_structured(name)
          elsif name.groupedValue.present?
            write_grouped(name)
          elsif name.value
            name.type == 'display' ? write_display_form(name) : write_basic(name)
          end
        end

        def write_contributor_with_parallel_names(parallel_name_values, contrib_name)
          display_type_parallel_name = display_type_parallel_name(parallel_name_values)
          if parallel_name_values.size == 1
            contrib_name_value_slice = NameTitleGroup.value_slices(parallel_name_values.first)
            name_title_group = name_title_vals_index[contrib_name_value_slice]&.values&.first
            write_name_from_parallel(contributor, contributor.name.first, parallel_name_values, name_title_group, nil)
          elsif parallel_name_values.size == 2 && display_type_parallel_name
            contrib_name_value_slice = NameTitleGroup.value_slices(parallel_name_values.first)
            name_title_group = name_title_vals_index[contrib_name_value_slice]&.values&.first
            write_name_with_display_form(contributor, contributor.name.first, parallel_name_values, 0, name_title_group, nil)
          else
            write_multiple_parallel_contributors(parallel_name_values, contrib_name)
          end
        end

        def write_multiple_parallel_contributors(parallel_name_values, contrib_name)
          altrepgroup_id = id_generator.next_altrepgroup
          parallel_name_values.each_with_index do |parallel_contrib_name, index|
            display_name_present = parallel_name_values[index + 1].present? && parallel_name_values[index + 1].type == 'display'
            NameTitleGroup.value_slices(parallel_contrib_name)&.each do |parallel_contrib_name_slice|
              if name_title_vals_index[parallel_contrib_name_slice]
                name_title_group = name_title_vals_index[parallel_contrib_name_slice]&.values&.first
                if display_name_present
                  # associate type 'display' with the previous value
                  write_name_with_display_form(contributor, contrib_name, parallel_name_values, index, name_title_group, altrepgroup_id)
                else
                  write_name_from_parallel(contributor, contrib_name, parallel_contrib_name, name_title_group, altrepgroup_id)
                end
              elsif display_name_present
                # TODO:  want a way to notify that we hit a problem - either notifier or HB error (issue #3751)
                #  OR validate for semantic correctness upon creation/update so we can't get here.
                #  notifier.warn("For contributor name '#{parallel_contrib_name_slice}', no contrib matching")
                write_name_with_display_form(contributor, contrib_name, parallel_name_values, index, nil, altrepgroup_id)
              elsif parallel_name_values[index].type == 'display'
                # we assume we included this as part of a previous name
                next
              else
                write_name_from_parallel(contributor, contrib_name, parallel_contrib_name, nil, altrepgroup_id)
              end
            end
          end
        end

        def write_name_from_parallel(contributor, name, parallel_name, name_title_group, altrepgroup_id)
          attributes = parallel_name_attributes(name, parallel_name, name_title_group, altrepgroup_id)
          type_attr = NAME_TYPE.fetch(contributor.type, name_title_group ? 'personal' : nil)
          attributes[:type] = type_attr if type_attr
          xml.name attributes do
            if parallel_name.structuredValue.present?
              write_structured(parallel_name)
            else
              write_basic(parallel_name)
            end
            write_identifier(contributor) if contributor.identifier.present?
            write_note(contributor)
            write_roles(contributor)
          end
        end

        def write_name_with_display_form(contributor, name, parallel_name_values, index, name_title_group, altrepgroup_id)
          display_type_parallel_name = display_type_parallel_name(parallel_name_values)
          parallel_name = parallel_name_values[index]
          return if parallel_name.blank?

          attributes = if altrepgroup_id.present?
                         parallel_name_attributes(name, parallel_name, name_title_group, altrepgroup_id)
                       else
                         name_attributes(contributor, name, nil)
                       end
          type_attr = NAME_TYPE.fetch(contributor.type, name_title_group ? 'personal' : nil)
          attributes[:type] = type_attr if type_attr
          xml.name attributes do
            if parallel_name.structuredValue.present?
              write_structured(parallel_name)
            else
              write_basic(parallel_name)
            end
            write_display_form(display_type_parallel_name) if display_type_parallel_name.present?
            write_identifier(contributor) if contributor.identifier.present?
            write_note(contributor)
            write_roles(contributor)
          end
        end

        def display_type_parallel_name(parallel_name_values)
          parallel_name_values.detect { |parallel_value| parallel_value.type == 'display' }
        end

        def parallel_name_attributes(name, parallel_name, name_title_group, altrepgroup_id)
          {
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
            nameTitleGroup: name_title_group,
            lang: name.valueLanguage&.code,
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
          Array(contributor.role).each do |role|
            RoleWriter.write(xml: xml, role: role)
          end
        end

        def write_basic(name)
          xml.namePart name.value, name_part_attributes(name)
        end

        def name_part_attributes(part)
          {
            type: NAME_PART[part.type]
          }.tap do |attributes|
            attributes['xlink:href'] = part.valueAt
          end.compact
        end

        def write_structured(name)
          Array(name.structuredValue).each do |part|
            xml.namePart part.value, name_part_attributes(part)
          end
        end

        def write_grouped(name)
          Array(name.groupedValue).each do |part|
            if part.type == 'pseudonym'
              xml.alternativeName part.value, name_part_attributes(part).merge({ altType: 'pseudonym' })
            elsif part.type == 'alternative'
              xml.alternativeName part.value, name_part_attributes(part)
            else
              write_name(part)
            end
          end
        end

        def write_note(contributor)
          Array(contributor.note).each do |note|
            case note.type
            when 'affiliation'
              xml.affiliation note.value
            when 'description'
              xml.description note.value
            when 'citation status'
              xml.description UNCITED_DESCRIPTION if note.value == 'false'
            end
          end
        end

        def write_identifier(contributor)
          contributor.identifier.each do |identifier|
            id_attributes = {
              displayLabel: identifier.displayLabel,
              typeURI: identifier.source&.uri,
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
