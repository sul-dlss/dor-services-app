# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps subjects from cocina to MODS XML
      class Subject
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
            # if note.parallelValue
            #   write_parallel(note, alt_rep_group: alt_rep_group)
            # else
            write_basic(subject)
            # end
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

        def write_basic(subject)
          attributes = {}
          # attributes[:displayLabel] = note.displayLabel if note.displayLabel
          xml.subject do
            xml.topic subject.value, attributes
          end
        end
      end
    end
  end
end
