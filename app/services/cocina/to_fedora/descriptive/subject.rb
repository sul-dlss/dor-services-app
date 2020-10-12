# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps subjects from cocina to MODS XML
      class Subject
        TAG_NAME = {
          'time' => :temporal
        }.freeze
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] subjects
        def self.write(xml:, subjects:)
          new(xml: xml, subjects: subjects).write
        end

        def initialize(xml:, subjects:)
          @xml = xml
          @subjects = subjects
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

        attr_reader :xml, :subjects

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
            subject.structuredValue&.each do |component|
              xml.public_send(TAG_NAME.fetch(component.type, :topic),
                              component.value,
                              topic_attributes_for(component))
            end
          end
        end

        def write_basic(subject)
          subject_attributes = {}
          subject_attributes[:authority] = subject.source.code if subject.source
          xml.subject(subject_attributes) do
            if subject.type == 'person'
              xml.name type: 'personal' do
                xml.namePart subject.value
              end
            else
              xml.topic subject.value, topic_attributes_for(subject)
            end
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
      end
    end
  end
end
