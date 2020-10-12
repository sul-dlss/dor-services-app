# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps notes from cocina to MODS XML
      class Note
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] notes
        def self.write(xml:, notes:)
          new(xml: xml, notes: notes).write
        end

        def initialize(xml:, notes:)
          @xml = xml
          @notes = notes
        end

        def write
          notes.each_with_index do |note, alt_rep_group|
            if note.parallelValue
              write_parallel(note, alt_rep_group: alt_rep_group)
            else
              write_basic(note)
            end
          end
        end

        private

        attr_reader :xml, :notes

        def write_parallel(note, alt_rep_group:)
          note.parallelValue.each do |descriptive_value|
            attributes = {
              altRepGroup: alt_rep_group,
              lang: descriptive_value.valueLanguage.code
            }
            attributes[:script] = descriptive_value.valueLanguage.valueScript.code

            xml.abstract(descriptive_value.value, attributes)
          end
        end

        def write_basic(note)
          xml.abstract note.value
        end
      end
    end
  end
end
