# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps subjects from cocina to MODS XML
      # rubocop:disable Metrics/ClassLength
      class Subject
        TAG_NAME = {
          'time' => :temporal,
          'genre' => :genre,
          'occupation' => :occupation
        }.freeze
        DEORDINAL_REGEX = /(?<=[0-9])(?:st|nd|rd|th)/.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] subjects
        # @params [Array<Cocina::Models::DescriptiveValue>] forms
        # @params [IdGenerator] id_generator
        def self.write(xml:, subjects:, id_generator:, forms: [])
          new(xml: xml, subjects: subjects, forms: forms, id_generator: id_generator).write
        end

        def initialize(xml:, subjects:, forms:, id_generator:)
          @xml = xml
          @subjects = Array(subjects)
          @forms = forms || []
          @id_generator = id_generator
        end

        def write
          subjects.each do |subject|
            next if subject.type == 'map coordinates'

            parallel_subject_values = Array(subject.parallelValue)
            subject_value = subject

            # Make adjustments for a parallel person.
            if parallel_subject_values.present? && FromFedora::Descriptive::Contributor::ROLES.values.include?(subject.type)
              display_values, parallel_subject_values = parallel_subject_values.partition { |value| value.type == 'display' }
              subject_value = parallel_subject_values.first if parallel_subject_values.size == 1
            end

            if parallel_subject_values.size > 1
              write_parallel(subject, parallel_subject_values, alt_rep_group: id_generator.next_altrepgroup, display_values: display_values)
            else
              write_subject(subject, subject_value, display_values: display_values)
            end
          end
          write_cartographic
        end

        private

        attr_reader :xml, :subjects, :forms, :id_generator

        def write_subject(subject, subject_value, alt_rep_group: nil, type: nil, display_values: nil)
          if subject_value.structuredValue
            write_structured(subject, subject_value, alt_rep_group: alt_rep_group, type: type, display_values: display_values)
          else
            write_basic(subject, subject_value, alt_rep_group: alt_rep_group, type: type, display_values: display_values)
          end
        end

        def write_parallel(subject, subject_values, alt_rep_group:, display_values: nil)
          if subject.type == 'place'
            xml.subject do
              subject_values.each do |geo|
                geographic(subject, geo, is_parallel: true)
              end
            end
          else
            subject_values.each do |subject_value|
              write_subject(subject, subject_value, alt_rep_group: alt_rep_group, type: subject.type, display_values: display_values)
            end
          end
        end

        def write_structured(subject, subject_value, alt_rep_group: nil, type: nil, display_values: nil)
          type ||= subject_value.type || subject.type
          xml.subject(structured_attributes_for(subject_value, alt_rep_group: alt_rep_group)) do
            if type == 'place'
              hierarchical_geographic(subject_value)
            elsif type == 'time'
              time_range(subject_value)
            elsif type == 'title'
              title = subject_value.to_h
              title.delete(:type)
              title.delete(:source)
              Title.write(xml: xml, titles: [Cocina::Models::DescriptiveValue.new(title)], id_generator: id_generator)
            elsif FromFedora::Descriptive::Contributor::ROLES.values.include?(type)
              write_structured_person(subject, subject_value, type: type, display_values: display_values)
            else
              Array(subject_value.structuredValue).each do |component|
                if FromFedora::Descriptive::Contributor::ROLES.values.include?(component.type)
                  if component.structuredValue
                    write_structured_person(subject, component, display_values: display_values)
                  else
                    write_person(subject, component, display_values: display_values)
                  end
                else
                  write_topic(subject, component, is_parallel: alt_rep_group.present?)
                end
              end
            end
          end
        end

        def structured_attributes_for(subject, alt_rep_group: nil)
          {
            altRepGroup: alt_rep_group,
            valueURI: subject.uri,
            displayLabel: subject.displayLabel
          }.tap do |attrs|
            if subject.source
              # If all values in structuredValue have uri, then authority only.
              attrs[:authority] = authority_for(subject)
              attrs[:authorityURI] = subject.source.uri if !all_values_have_uri?(subject.structuredValue) || subject.uri
            elsif all_values_have_lcsh_authority?(subject.structuredValue)
              # No source, but all values in structuredValue are lcsh or naf then add authority
              attrs[:authority] = 'lcsh'
            end
            attrs[:lang] = subject.valueLanguage&.code
            attrs[:script] = subject.valueLanguage&.valueScript&.code
          end.compact
        end

        def all_values_have_uri?(structured_value)
          structured_value.present? && Array(structured_value).all?(&:uri)
        end

        def all_values_have_lcsh_authority?(structured_value)
          structured_value.present? && Array(structured_value).all? { |value| authority_for(value) == 'lcsh' }
        end

        def write_basic(subject, subject_value, alt_rep_group: nil, type: nil, display_values: nil)
          subject_attributes = subject_attributes_for(subject_value, alt_rep_group)
          type ||= subject_value.type

          if type == 'classification'
            write_classification(subject_value.value, subject_attributes)
          elsif FromFedora::Descriptive::Contributor::ROLES.values.include?(type) || type == 'name'
            xml.subject(subject_attributes) do
              write_person(subject, subject_value, display_values: display_values)
            end
          else
            xml.subject(subject_attributes) do
              write_topic(subject, subject_value, is_parallel: alt_rep_group.present?)
            end
          end
        end

        def subject_attributes_for(subject, alt_rep_group)
          {
            altRepGroup: alt_rep_group,
            authority: authority_for(subject),
            lang: subject.valueLanguage&.code,
            script: subject.valueLanguage&.valueScript&.code,
            usage: subject.status
          }.tap do |attrs|
            attrs[:displayLabel] = subject.displayLabel unless subject.type == 'genre'
            attrs[:edition] = edition(subject.source.version) if subject.source&.version
          end.compact
        end

        def authority_for(subject)
          # Authority for place is on the geographicCode, not the subject.
          # See "Geographic code subject" example.
          return nil if subject.type == 'place' && subject.source&.code == 'marcgac'

          # Both lcsh and naf map to lcsh for the subject.
          return 'lcsh' if %w[lcsh naf].include?(subject.source&.code)

          subject.source&.code
        end

        def write_classification(value, attrs)
          xml.classification value, attrs
        end

        def write_topic(subject, subject_value, is_parallel: false)
          topic_attributes = topic_attributes_for(subject_value, is_parallel: is_parallel)
          case subject_value.type
          when 'person'
            xml.name topic_attributes.merge(type: 'personal') do
              xml.namePart(subject_value.value) if subject_value.value
            end
          when 'title'
            title = subject_value.to_h
            title.delete(:type)
            title[:source].delete(:code) if subject_value.source&.code && !topic_attributes[:authority]
            Title.write(xml: xml, titles: [Cocina::Models::DescriptiveValue.new(title)], id_generator: id_generator, additional_attrs: topic_attributes)
          when 'place'
            geographic(subject, subject_value, is_parallel: is_parallel)
          else
            xml.public_send(TAG_NAME.fetch(subject_value.type, :topic), subject_value.value, topic_attributes)
          end
        end

        def topic_attributes_for(subject_value, is_parallel: false, is_geo: false)
          {
            authority: authority_for_topic(subject_value, is_geo, is_parallel),
            authorityURI: subject_value.source&.uri,
            encoding: subject_value.encoding&.code,
            valueURI: subject_value.uri
          }.tap do |topic_attributes|
            if subject_value.type == 'genre'
              topic_attributes[:displayLabel] = subject_value.displayLabel
              topic_attributes[:usage] = subject_value.status
            end
            topic_attributes['xlink:href'] = subject_value.valueAt
          end.compact
        end

        def authority_for_topic(subject_value, is_geo, is_parallel)
          return nil unless subject_value.source&.uri || subject_value.uri || (is_geo && is_parallel)

          subject_value.source&.code
        end

        def geographic(_subject, subject_value, is_parallel: false)
          if subject_value.code
            xml.geographicCode subject_value.code, authority: subject_value.source.code
          else
            xml.geographic subject_value.value, topic_attributes_for(subject_value, is_parallel: is_parallel, is_geo: true)
          end
        end

        def time_range(subject)
          subject.structuredValue.each do |point|
            xml.temporal point.value, point: point.type, encoding: subject.encoding.code
          end
        end

        def write_cartographic
          write_cartographic_without_authority
          write_cartographic_with_authority
        end

        def write_cartographic_without_authority
          # With all subject/forms without authorities.
          scale_forms = forms.select { |form| form.type == 'map scale' }
          projection_forms = forms.select { |form| form.type == 'map projection' && form.source.nil? }
          carto_subjects = subjects.select { |subject| subject.type == 'map coordinates' }
          return unless scale_forms.present? || projection_forms.present? || carto_subjects.present?

          xml.subject do
            xml.cartographics do
              scale_forms.each { |scale_form| xml.scale scale_form.value }
              projection_forms.each { |projection_form| xml.projection projection_form.value }
              carto_subjects.each { |carto_subject| xml.coordinates carto_subject.value }
            end
          end
        end

        def write_cartographic_with_authority
          # Each for form with authority.
          projection_forms_with_authority = forms.select { |form| form.type == 'map projection' && form.source.present? }
          projection_forms_with_authority.each do |projection_form|
            xml.subject carto_subject_attributes_for(projection_form) do
              xml.cartographics do
                xml.projection projection_form.value
              end
            end
          end
        end

        def carto_subject_attributes_for(form)
          {
            displayLabel: form.displayLabel,
            authority: form.source&.code,
            authorityURI: form.source&.uri,
            valueURI: form.uri
          }.compact
        end

        def hierarchical_geographic(subject)
          xml.hierarchicalGeographic do
            subject.structuredValue.each { |structured_value| xml.send(structured_value.type, structured_value.value) }
          end
        end

        def write_person(subject, subject_value, display_values: nil)
          name_attrs = topic_attributes_for(subject_value).tap do |attrs|
            attrs[:type] = name_type_for(subject_value.type || subject.type)
          end.compact
          xml.name name_attrs do
            xml.namePart subject_value.value if subject_value.value
            write_display_form(display_values)
            write_roles(subject.note)
          end
        end

        def write_structured_person(subject, subject_value, type: nil, display_values: nil)
          type ||= subject_value.type
          name_attrs = {
            type: name_type_for(type)
          }.compact

          xml.name name_attrs do
            write_name_parts(subject_value)
            write_display_form(display_values)
            write_roles(subject.note)
          end
        end

        def write_display_form(display_values)
          Array(display_values).each do |display_value|
            xml.displayForm display_value.value
          end
        end

        def write_roles(notes)
          Array(notes).filter { |note| note.type == 'role' }.each { |role| RoleWriter.write(xml: xml, role: role) }
        end

        def write_name_parts(descriptive_value)
          descriptive_value.structuredValue.each do |point|
            attributes = {}.tap do |attrs|
              attrs[:type] = FromFedora::Descriptive::Contributor::NAME_PART.invert[point.type]
            end.compact
            xml.namePart point.value, attributes
          end
        end

        def name_type_for(type)
          FromFedora::Descriptive::Contributor::ROLES.invert[type]
        end

        def edition(version)
          version.split.first.gsub(DEORDINAL_REGEX, '')
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
