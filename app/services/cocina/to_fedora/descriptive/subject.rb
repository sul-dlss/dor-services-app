# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps subjects from cocina to MODS XML
      class Subject
        TAG_NAME = {
          'time' => :temporal,
          'genre' => :genre,
          'place' => :geographic
        }.freeze
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] subjects
        # @params [Array<Cocina::Models::DescriptiveValue>] forms
        def self.write(xml:, subjects:, forms: [])
          new(xml: xml, subjects: subjects, forms: forms).write
        end

        def initialize(xml:, subjects:, forms:)
          @xml = xml
          @subjects = subjects
          @forms = forms
        end

        def write
          subjects.each_with_index do |subject, _alt_rep_group|
            if subject.structuredValue
              write_structured(subject)
            else
              write_basic(subject)
            end
          end
        end

        private

        attr_reader :xml, :subjects, :forms

        # def write_parallel(note, alt_rep_group:)
        #   note.parallelValue.each do |descriptive_value|
        #     attributes = {
        #       altRepGroup: alt_rep_group,
        #       lang: descriptive_value.valueLanguage.code
        #     }
        #     attributes[:script] = descriptive_value.valueLanguage.valueScript.code
        #
        #     xml.abstract(descriptive_value.value, attributes)
        #   end
        # end

        def write_structured(subject)
          subject_attributes = {}
          if subject.source
            subject_attributes[:authority] = subject.source.code
            subject_attributes[:authorityURI] = subject.source.uri
          elsif subject.structuredValue&.first&.source
            subject_attributes[:authority] = subject.structuredValue.first.source.code
          end
          subject_attributes[:valueURI] = subject.uri if subject.uri

          xml.subject(subject_attributes) do
            if subject.type == 'place'
              hierarchical_geographic(xml, subject)
            else
              subject.structuredValue&.each do |component|
                write_topic(component)
              end
            end
          end
        end

        def write_basic(subject)
          subject_attributes = {}
          subject_attributes[:authority] = subject.source.code if subject.source
          xml.subject(subject_attributes) do
            write_topic(subject)
          end
        end

        def write_topic(subject)
          if subject.type == 'person'
            xml.name topic_attributes_for(subject).merge(type: 'personal') do
              xml.namePart subject.value
            end
          elsif subject.type == 'title'
            xml.titleInfo topic_attributes_for(subject) do
              xml.title subject.value
            end
          elsif subject.type == 'map coordinates'
            cartographics(xml, subject)
          else
            xml.public_send(TAG_NAME.fetch(subject.type, :topic),
                            subject.value,
                            topic_attributes_for(subject))
          end
        end

        def topic_attributes_for(subject)
          {}.tap do |topic_attributes|
            if subject.source
              topic_attributes[:authority] = subject.source.code
              topic_attributes[:authorityURI] = subject.source.uri
            end
            topic_attributes[:valueURI] = subject.uri if subject.uri
          end
        end

        def cartographics(xml, subject)
          xml.cartographics do
            xml.coordinates subject.value
            xml.scale forms.find { |form| form.type == 'map scale' }.value
            xml.projection forms.find { |form| form.type == 'map projection' }.value
          end
        end

        def hierarchical_geographic(xml, subject)
          xml.hierarchicalGeographic do
            xml.country subject.structuredValue.find { |geo| geo.type == 'country' }.value
            xml.city subject.structuredValue.find { |geo| geo.type == 'city' }.value
          end
        end
      end
    end
  end
end
