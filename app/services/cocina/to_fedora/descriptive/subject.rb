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
            type = nil

            # Make adjustments for a parallel person.
            if parallel_subject_values.present? && FromFedora::Descriptive::Contributor::ROLES.value?(subject.type)
              display_values, parallel_subject_values = parallel_subject_values.partition { |value| value.type == 'display' }
              if parallel_subject_values.size == 1
                subject_value = parallel_subject_values.first
                parallel_subject_values = []
                type = subject.type
              end
            end

            if parallel_subject_values.size > 1
              write_parallel(subject, parallel_subject_values, alt_rep_group: id_generator.next_altrepgroup, display_values: display_values)
            else
              write_subject(subject, subject_value, display_values: display_values, type: type)
            end
          end
          write_cartographic
        end

        private

        attr_reader :xml, :subjects, :forms, :id_generator

        def write_subject(subject, subject_value, alt_rep_group: nil, type: nil, display_values: nil)
          if subject_value.structuredValue || subject_value.groupedValue
            write_structured_or_grouped(subject, subject_value, alt_rep_group: alt_rep_group, type: type, display_values: display_values)
          else
            write_basic(subject, subject_value, alt_rep_group: alt_rep_group, type: type, display_values: display_values)
          end
        end

        def write_parallel(subject, subject_values, alt_rep_group:, display_values: nil)
          # A geographic and geographicCode get written as a single subject.
          if geographic_and_geographic_code?(subject, subject_values)
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

        def geographic_and_geographic_code?(subject, subject_values)
          subject.type == 'place' &&
            subject_values.count(&:value) == 1 &&
            subject_values.count(&:code) == 1
        end

        # rubocop:disable Metrics/PerceivedComplexity
        def write_structured_or_grouped(subject, subject_value, alt_rep_group: nil, type: nil, display_values: nil)
          type ||= subject_value.type || subject.type
          xml.subject(structured_attributes_for(subject_value, alt_rep_group: alt_rep_group)) do
            if type == 'place' && subject_value.structuredValue
              hierarchical_geographic(subject_value)
            elsif type == 'time'
              time_range(subject_value)
            elsif type == 'title'
              write_title(subject_value)
            elsif FromFedora::Descriptive::Contributor::ROLES.value?(type)
              write_structured_person(subject, subject_value, type: type, display_values: display_values)
            else
              values = Array(subject_value.structuredValue || subject_value.groupedValue)
              values.each do |value|
                if FromFedora::Descriptive::Contributor::ROLES.value?(value.type)
                  if value.structuredValue
                    write_structured_person(subject, value, display_values: display_values)
                  else
                    write_person(subject, value, display_values: display_values)
                  end
                else
                  write_topic(subject, value, is_parallel: alt_rep_group.present?, type: type,
                                              subject_values_have_same_authority: all_values_have_same_authority?(values))
                end
              end
            end
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity

        def write_title(subject_value)
          title = subject_value.to_h
          title.delete(:type)
          title.delete(:source)
          title.delete(:valueLanguage)
          Title.write(xml: xml, titles: [Cocina::Models::DescriptiveValue.new(title)], id_generator: id_generator)
        end

        # rubocop:disable Metrics/PerceivedComplexity
        def structured_attributes_for(subject, alt_rep_group: nil)
          values = subject.structuredValue || subject.groupedValue
          {
            altRepGroup: alt_rep_group,
            displayLabel: subject.displayLabel,
            lang: subject.valueLanguage&.code,
            script: subject.valueLanguage&.valueScript&.code
          }.tap do |attrs|
            if subject.type == 'person'
              attrs[:authority] = authority_for(subject)
            else
              attrs[:valueURI] = subject.uri
              if subject.source
                # If all values in structuredValue have uri, then authority only.
                attrs[:authority] = authority_for(subject)
                attrs[:authorityURI] = subject.source.uri if !all_values_have_uri?(values) || subject.uri
              elsif all_values_have_lcsh_authority?(values)
                # No source, but all values in structuredValue are lcsh or naf then add authority
                attrs[:authority] = 'lcsh'
              elsif subject.type == 'place' && all_values_have_same_authority?(values)
                attrs[:authority] = authority_for(values.first)
              end
            end
          end.compact
        end
        # rubocop:enable Metrics/PerceivedComplexity

        def all_values_have_uri?(values)
          values.present? && Array(values).all?(&:uri)
        end

        def all_values_have_lcsh_authority?(values)
          values.present? && Array(values).all? { |value| authority_for(value) == 'lcsh' }
        end

        def all_values_have_same_authority?(values)
          return false if values.blank?

          check_authority = authority_for(values.first)
          return false if check_authority.nil?

          values.all? { |value| authority_for(value) == check_authority }
        end

        def write_basic(subject, subject_value, alt_rep_group: nil, type: nil, display_values: nil)
          subject_attributes = subject_attributes_for(subject_value, alt_rep_group)
          type ||= subject_value.type

          if type == 'classification'
            write_classification(subject_value.value, subject_attributes)
          elsif FromFedora::Descriptive::Contributor::ROLES.value?(type) || type == 'name'
            xml.subject(subject_attributes) do
              write_person(subject, subject_value, display_values: display_values)
            end
          elsif !type && !subject_value.value
            # For subject only (no children).
            xml.subject subject_attributes.merge(topic_attributes_for(subject, subject_value))
          else
            xml.subject(subject_attributes) do
              write_topic(subject, subject_value, type: type)
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
            attrs['xlink:href'] = subject.valueAt
          end.compact
        end

        def authority_for(subject)
          # Both lcsh and naf map to lcsh for the subject.
          return 'lcsh' if %w[lcsh naf].include?(subject.source&.code)

          subject.source&.code
        end

        def write_classification(value, attrs)
          xml.classification value, attrs
        end

        def write_topic(subject, subject_value, is_parallel: false, type: nil, subject_values_have_same_authority: true)
          topic_attributes = topic_attributes_for(subject, subject_value, is_parallel: is_parallel, subject_values_have_same_authority: subject_values_have_same_authority)
          case type || subject_value.type
          when 'person'
            xml.name topic_attributes.merge(type: 'personal') do
              xml.namePart(subject_value.value) if subject_value.value
            end
          when 'title'
            title = subject_value.to_h
            title.delete(:type)
            title.delete(:valueLanguage)
            title[:source].delete(:code) if subject_value.source&.code && !topic_attributes[:authority]
            Title.write(xml: xml, titles: [Cocina::Models::DescriptiveValue.new(title)], id_generator: id_generator, additional_attrs: topic_attributes)
          when 'place'
            geographic(subject, subject_value, is_parallel: is_parallel)
          else
            xml.public_send(TAG_NAME.fetch(subject_value.type, :topic), subject_value.value, topic_attributes)
          end
        end

        def topic_attributes_for(subject, subject_value, is_parallel: false, is_geo: false, subject_values_have_same_authority: true)
          {
            authority: authority_for_topic(subject, subject_value, is_geo, is_parallel, subject_values_have_same_authority),
            authorityURI: subject_value.source&.uri,
            encoding: subject_value.encoding&.code,
            valueURI: subject_value.uri
          }.tap do |topic_attributes|
            if subject_value.type == 'genre'
              topic_attributes[:displayLabel] = subject_value.displayLabel
              topic_attributes[:usage] = subject_value.status
            end
          end.compact
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def authority_for_topic(subject, subject_value, is_geo, is_parallel, subject_values_have_same_authority)
          return nil unless subject_value.source&.uri ||
                            subject_value.uri ||
                            (is_geo && is_parallel) ||
                            (subject_value.source&.code && subject.source&.code && subject.source.code != subject_value.source.code) ||
                            (subject_value.source&.code && !subject_values_have_same_authority)

          subject_value.source&.code
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        def geographic(subject, subject_value, is_parallel: false)
          if subject_value.code
            xml.geographicCode subject_value.code, topic_attributes_for(subject, subject_value, is_parallel: is_parallel, is_geo: true)
          else
            xml.geographic subject_value.value, topic_attributes_for(subject, subject_value, is_parallel: is_parallel, is_geo: true)
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
          name_attrs = topic_attributes_for(subject, subject_value).tap do |attrs|
            attrs[:type] = name_type_for(subject.type || subject_value.type)
          end.compact
          xml.name name_attrs do
            write_name_part(subject_value)
            write_display_form(display_values)
            write_roles(subject.note)
          end
        end

        def write_structured_person(subject, subject_value, type: nil, display_values: nil)
          type ||= subject_value.type
          name_attrs = topic_attributes_for(subject, subject_value).tap do |attrs|
            attrs[:type] = name_type_for(type)
          end.compact

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
          descriptive_value.structuredValue.each do |value|
            write_name_part(value)
          end
        end

        def write_name_part(name_part)
          return unless name_part.value

          attributes = {}.tap do |attrs|
            attrs[:type] = ToFedora::Descriptive::ContributorWriter::NAME_PART[name_part.type]
          end.compact
          xml.namePart name_part.value, attributes
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
