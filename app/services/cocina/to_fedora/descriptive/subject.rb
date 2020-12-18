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

            if subject.structuredValue
              write_structured(subject)
            elsif subject.parallelValue
              write_parallel(subject, alt_rep_group: id_generator.next_altrepgroup)
            else
              write_basic(subject)
            end
          end
          write_cartographic
        end

        private

        attr_reader :xml, :subjects, :forms, :id_generator

        def write_subject(subject, alt_rep_group: nil, type: nil)
          if subject.structuredValue
            write_structured(subject, alt_rep_group: alt_rep_group, type: type)
          else
            write_basic(subject, alt_rep_group: alt_rep_group, type: type)
          end
        end

        def write_parallel(subject, alt_rep_group:)
          if subject.type == 'place'
            xml.subject do
              subject.parallelValue.each do |geo|
                geographic(geo, is_parallel: true)
              end
            end
          else
            subject.parallelValue.each { |parallel_subject| write_subject(parallel_subject, alt_rep_group: alt_rep_group, type: subject.type) }
          end
        end

        def write_structured(subject, alt_rep_group: nil, type: nil)
          type ||= subject.type
          xml.subject(structured_attributes_for(subject, alt_rep_group: alt_rep_group)) do
            if type == 'place'
              hierarchical_geographic(subject)
            elsif type == 'time'
              time_range(subject)
            elsif FromFedora::Descriptive::Contributor::ROLES.values.include?(type)
              structured_person(subject, type: type)
            else
              subject.structuredValue&.each do |component|
                if FromFedora::Descriptive::Contributor::ROLES.values.include?(component.type)
                  if component.structuredValue
                    structured_person(component)
                  else
                    person(component)
                  end
                else
                  write_topic(component, is_parallel: alt_rep_group.present?)
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
              attrs[:authority] = authority_for(subject)
              attrs[:authorityURI] = subject.source.uri
            elsif all_same_authority?(subject.structuredValue)
              attrs[:authority] = authority_for(subject.structuredValue.first)
            end
            attrs[:lang] = subject.valueLanguage&.code
            attrs[:script] = subject.valueLanguage&.valueScript&.code
          end.compact
        end

        def all_same_authority?(structured_value)
          Array(structured_value).map { |value| authority_for(value) }.uniq.size == 1
        end

        def write_basic(subject, alt_rep_group: nil, type: nil)
          subject_attributes = subject_attributes_for(subject, alt_rep_group)
          type ||= subject.type

          if type == 'classification'
            write_classification(subject.value, subject_attributes)
          elsif FromFedora::Descriptive::Contributor::ROLES.values.include?(type) || type == 'name'
            xml.subject(subject_attributes) do
              person(subject)
            end
          else
            xml.subject(subject_attributes) do
              write_topic(subject, is_parallel: alt_rep_group.present?, is_basic: true)
            end
          end
        end

        def subject_attributes_for(subject, alt_rep_group)
          {
            altRepGroup: alt_rep_group,
            authority: authority_for(subject),
            displayLabel: subject.displayLabel
          }.tap do |attrs|
            attrs[:edition] = edition(subject.source.version) if subject.source&.version
            if alt_rep_group
              attrs[:lang] = subject.valueLanguage&.code
              attrs[:script] = subject.valueLanguage&.valueScript&.code
            end
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

        def write_topic(subject, is_parallel: false, is_basic: false)
          case subject.type
          when 'person'
            xml.name topic_attributes_for(subject, is_parallel: is_parallel, is_basic: is_basic).merge(type: 'personal') do
              xml.namePart subject.value
            end
          when 'title'
            xml.titleInfo topic_attributes_for(subject, is_parallel: is_parallel, is_basic: is_basic) do
              xml.title subject.value
            end
          when 'place'
            geographic(subject, is_parallel: is_parallel)
          else
            xml.public_send(TAG_NAME.fetch(subject.type, :topic),
                            subject.value,
                            topic_attributes_for(subject, is_parallel: is_parallel, is_basic: is_basic))
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def topic_attributes_for(subject, is_parallel: false, is_geo: false, is_basic: false)
          {}.tap do |topic_attributes|
            topic_attributes[:authority] = subject.source&.code if subject.source&.uri || subject.uri || (is_geo && is_parallel)
            topic_attributes[:authorityURI] = subject.source&.uri
            topic_attributes[:encoding] = subject.encoding&.code
            topic_attributes[:valueURI] = subject.uri
            if is_geo || (is_basic && !is_parallel)
              topic_attributes[:lang] = subject.valueLanguage&.code
              topic_attributes[:script] = subject.valueLanguage&.valueScript&.code
            end
          end.compact
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        def geographic(subject, is_parallel: false)
          if subject.code
            xml.geographicCode subject.code, authority: subject.source.code
          else
            xml.geographic subject.value, topic_attributes_for(subject, is_parallel: is_parallel, is_geo: true)
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

        def person(subject)
          subject_attributes = topic_attributes_for(subject).tap do |attrs|
            attrs[:type] = name_type_for(subject.type)
          end.compact

          xml.name subject_attributes do
            xml.namePart subject.value
          end
        end

        def structured_person(subject, type: nil)
          type ||= subject.type
          name_attrs = {
            type: name_type_for(type)
          }.compact
          xml.name name_attrs do
            subject.structuredValue.each do |point|
              attributes = {}.tap do |attrs|
                attrs[:type] = FromFedora::Descriptive::Contributor::NAME_PART.invert[point.type]
              end.compact
              xml.namePart point.value, attributes
            end
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
