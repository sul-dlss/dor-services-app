# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps notes from cocina to MODS XML
      class Note
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] notes
        def self.write(xml:, notes:)
          Array(notes).each_with_index do |note, alt_rep_group|
            if note.parallelValue
              write_parallel(xml, note, alt_rep_group: alt_rep_group)
            else
              write_basic(xml, note)
            end
          end
        end

        def self.tag_name(type)
          type == 'summary' ? :abstract : :note
        end
        private_class_method :tag_name

        def self.tag(xml, note, tag_name, attributes)
          attributes[:type] = note.type if note.type && tag_name != :abstract
          xml.public_send tag_name, note.value, attributes
        end
        private_class_method :tag

        def self.write_basic(xml, note)
          attributes = {}
          attributes[:displayLabel] = note.displayLabel if note.displayLabel
          tag(xml, note, tag_name(note.type), attributes)
        end

        def self.write_parallel(xml, note, alt_rep_group:)
          note.parallelValue.each do |descriptive_value|
            attributes = {
              altRepGroup: alt_rep_group,
              lang: descriptive_value.valueLanguage.code
            }
            attributes[:script] = descriptive_value.valueLanguage.valueScript.code if descriptive_value.valueLanguage.valueScript

            tag(xml, descriptive_value, tag_name(note.type), attributes)
          end
        end
        private_class_method :write_parallel
      end
    end
  end
end
