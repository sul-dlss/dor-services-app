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
        end

        def write
          subjects.each_with_index do |subject, alt_rep_group|
            if subject.structuredValue
              write_structured(subject)
            elsif subject.parallelValue
              write_parallel(subject, alt_rep_group: alt_rep_group)
            else
              write_basic(subject)
            end
          end
        end

        private

        attr_reader :xml, :subjects, :forms

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
          subject_attributes = {}
          if subject.source
            subject_attributes[:authority] = subject.source.code
            subject_attributes[:authorityURI] = subject.source.uri if subject.source.uri
          elsif subject.structuredValue&.first&.source
            subject_attributes[:authority] = subject.structuredValue.first.source.code
          end
          subject_attributes[:valueURI] = subject.uri if subject.uri

          xml.subject(subject_attributes) do
            case subject.type
            when 'place'
              hierarchical_geographic(xml, subject)
            when 'time'
              time_range(xml, subject)
            when 'person'
              person(xml, subject)
            else
              subject.structuredValue&.each do |component|
                write_topic(component)
              end
            end
          end
        end

        def write_basic(subject)
          subject_attributes = {}
          subject_attributes[:authority] = 'lcsh' if subject.source && subject.type != 'place'
          subject_attributes[:displayLabel] = subject.displayLabel if subject.displayLabel
          subject_attributes[:edition] = edition(subject.source.version) if subject.source&.version

          case subject.type
          when 'classification'
            subject_attributes[:authority] = subject.source.code
            write_classification(subject.value, subject_attributes)
          else
            xml.subject(subject_attributes) do
              write_topic(subject)
            end
          end
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

        def cartographics(xml, subject)
          xml.cartographics do
            xml.coordinates subject.value
            scale = forms.find { |form| form.type == 'map scale' }
            xml.scale scale.value if scale
            projection = forms.find { |form| form.type == 'map projection' }
            xml.projection projection.value if projection
          end
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
          xml.name type: 'personal' do
            subject.structuredValue.each do |point|
              attributes = {}
              attributes[:type] = FromFedora::Descriptive::Contributor::NAME_PART.invert.fetch(point.type) if point.type != 'name'
              xml.namePart point.value, attributes
            end
          end
        end

        def edition(version)
          version.split.first.gsub(DEORDINAL_REGEX, '')
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
