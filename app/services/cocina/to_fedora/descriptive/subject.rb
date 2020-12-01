# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps subjects from cocina to MODS XML
      # rubocop:disable Metrics/ClassLength
      class Subject
        TAG_NAME = {
          'time' => :temporal,
          'genre' => :genre
        }.freeze
        DEORDINAL_REGEX = /(?<=[0-9])(?:st|nd|rd|th)/.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] subjects
        # @params [Array<Cocina::Models::DescriptiveValue>] forms
        def self.write(xml:, subjects:, forms: [])
          new(xml: xml, subjects: subjects, forms: forms).write
        end

        def initialize(xml:, subjects:, forms:)
          @xml = xml
          @subjects = Array(subjects)
          @forms = forms
          # Used to determine if need to write form only cartographics
          @wrote_cartographic = false
        end

        def write
          subjects.each_with_index do |subject, index|
            if subject.structuredValue
              write_structured(subject)
            elsif subject.parallelValue
              write_parallel(subject, alt_rep_group: index)
            else
              write_basic(subject)
            end
          end
          write_form_only_cartographic
        end

        private

        attr_reader :xml, :subjects, :forms, :wrote_cartographic

        def write_parallel(subject, alt_rep_group:)
          if subject.type == 'place'
            xml.subject do
              subject.parallelValue.each do |geo|
                geographic(geo)
              end
            end
          else
            subject.parallelValue.each do |val|
              xml.subject lang: val.valueLanguage.code, altRepGroup: alt_rep_group do
                write_topic(val)
              end
            end
          end
        end

        def write_structured(subject)
          xml.subject(structured_attributes_for(subject)) do
            if subject.type == 'place'
              hierarchical_geographic(xml, subject)
            elsif subject.type == 'time'
              time_range(xml, subject)
            elsif FromFedora::Descriptive::Contributor::ROLES.values.include?(subject.type)
              structured_person(xml, subject)
            else
              subject.structuredValue&.each do |component|
                if FromFedora::Descriptive::Contributor::ROLES.values.include?(component.type)
                  if component.structuredValue
                    structured_person(xml, component)
                  else
                    person(xml, component)
                  end
                else
                  write_topic(component)
                end
              end
            end
          end
        end

        def structured_attributes_for(subject)
          {}.tap do |attrs|
            if subject.source
              attrs[:authority] = authority_for(subject)
              attrs[:authorityURI] = subject.source.uri
            elsif all_same_authority?(subject.structuredValue)
              attrs[:authority] = authority_for(subject.structuredValue.first)
            end
            attrs[:valueURI] = subject.uri
          end.compact
        end

        def all_same_authority?(structured_value)
          Array(structured_value).map { |value| authority_for(value) }.uniq.size == 1
        end

        def write_basic(subject)
          subject_attributes = {}.tap do |attrs|
            attrs[:authority] = authority_for(subject)
            attrs[:displayLabel] = subject.displayLabel
            attrs[:edition] = edition(subject.source.version) if subject.source&.version
          end.compact

          if subject.type == 'classification'
            write_classification(subject.value, subject_attributes)
          elsif FromFedora::Descriptive::Contributor::ROLES.values.include?(subject.type)
            xml.subject(subject_attributes) do
              person(xml, subject)
            end
          else
            xml.subject(subject_attributes) do
              write_topic(subject)
            end
          end
        end

        def authority_for(subject)
          # Authority for place is on the geographicCode, not the subject.
          # See "Geographic code subject" example.
          return nil if subject.type == 'place'

          # Both lcsh and naf map to lcsh for the subject.
          return 'lcsh' if %w[lcsh naf].include?(subject.source&.code)

          subject.source&.code
        end

        def write_classification(value, attrs)
          xml.classification value, attrs
        end

        def write_topic(subject)
          case subject.type
          when 'person'
            xml.name topic_attributes_for(subject).merge(type: 'personal') do
              xml.namePart subject.value
            end
          when 'title'
            xml.titleInfo topic_attributes_for(subject) do
              xml.title subject.value
            end
          when 'map coordinates'
            cartographics(xml, subject)
          when 'place'
            geographic(subject)
          else
            xml.public_send(TAG_NAME.fetch(subject.type, :topic),
                            subject.value,
                            topic_attributes_for(subject))
          end
        end

        def topic_attributes_for(subject)
          {}.tap do |topic_attributes|
            if subject.source&.uri
              topic_attributes[:authority] = subject.source.code
              topic_attributes[:authorityURI] = subject.source.uri
            end
            topic_attributes[:encoding] = subject.encoding.code if subject.encoding
            topic_attributes[:valueURI] = subject.uri if subject.uri
          end
        end

        def geographic(subject)
          if subject.code
            xml.geographicCode subject.code, authority: subject.source.code
          else
            attrs = {}
            attrs[:authority] = subject.source.code if subject.source
            xml.geographic subject.value, attrs
          end
        end

        def time_range(xml, subject)
          subject.structuredValue.each do |point|
            xml.temporal point.value, point: point.type, encoding: subject.encoding.code
          end
        end

        def cartographics(xml, subject = nil)
          xml.cartographics do
            xml.coordinates subject.value if subject
            xml.scale scale_form.value if scale_form
            xml.projection projection_form.value if projection_form
          end
          @wrote_cartographic = true
        end

        def write_form_only_cartographic
          return if wrote_cartographic
          return unless scale_form || projection_form

          xml.subject do
            cartographics(xml)
          end
        end

        def scale_form
          @scale_form ||= forms&.find { |form| form.type == 'map scale' }
        end

        def projection_form
          @projection_form ||= forms&.find { |form| form.type == 'map projection' }
        end

        def hierarchical_geographic(xml, subject)
          xml.hierarchicalGeographic do
            continent = subject.structuredValue.find { |geo| geo.type == 'continent' }&.value
            xml.continent continent if continent
            country = subject.structuredValue.find { |geo| geo.type == 'country' }&.value
            xml.country country if country
            city = subject.structuredValue.find { |geo| geo.type == 'city' }&.value
            xml.city city if city
          end
        end

        def person(xml, subject)
          subject_attributes = {}.tap do |attrs|
            attrs[:type] = name_type_for(subject)
            if subject.source
              attrs[:authority] = subject.source.code
              attrs[:authorityURI] = subject.source.uri
            end
            attrs[:valueURI] = subject.uri
          end.compact

          xml.name subject_attributes do
            xml.namePart subject.value
          end
        end

        def structured_person(xml, subject)
          xml.name type: name_type_for(subject) do
            subject.structuredValue.each do |point|
              attributes = {}
              attributes[:type] = FromFedora::Descriptive::Contributor::NAME_PART.invert.fetch(point.type) unless ['name', 'inverted full name'].include?(point.type)
              xml.namePart point.value, attributes
            end
          end
        end

        def name_type_for(subject)
          FromFedora::Descriptive::Contributor::ROLES.invert.fetch(subject.type)
        end

        def edition(version)
          version.split.first.gsub(DEORDINAL_REGEX, '')
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
