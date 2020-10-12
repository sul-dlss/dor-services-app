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
          end
          subject_attributes[:valueURI] = subject.uri if subject.uri

          xml.subject(subject_attributes) do
            subject.structuredValue&.each do |component|
              xml.public_send(TAG_NAME.fetch(component.type, :topic), component.value)
            end
          end
        end

        def write_basic(subject)
          subject_attributes = {}
          subject_attributes[:authority] = subject.source.code if subject.source
          xml.subject(subject_attributes) do
            topic_attributes = subject_attributes.dup
            topic_attributes[:valueURI] = subject.uri if subject.uri
            topic_attributes[:authorityURI] = subject.source.uri if subject.source
            xml.topic subject.value, topic_attributes
          end
        end
      end
    end
  end
end
