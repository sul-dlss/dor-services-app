# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps notes from cocina to MODS XML
      class Note
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] notes
        def self.write(xml:, notes:)
          Array(notes).each_with_index do |note, index|
            if note.parallelValue
              write_parallel(xml, note, alt_rep_group: index)
            else
              write_basic(xml, note)
            end
          end
        end

        def self.tag_name(type)
          # type == 'summary' ? :abstract : :note
          case type
          when 'summary'
            :abstract
          when 'table of contents'
            :tableOfContents
          else
            :note
          end
        end
        private_class_method :tag_name

        def self.tag(xml, note, tag_name, attributes)
          attributes[:type] = note.type if note.type && [:abstract, :tableOfContents].exclude?(tag_name)
          value = if note.structuredValue
                    note.structuredValue.map(&:value).join(' -- ')
                  else
                    note.value
                  end
          xml.public_send tag_name, value, attributes
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
              lang: descriptive_value.valueLanguage&.code,
              script: descriptive_value.valueLanguage&.valueScript&.code
            }.compact

            tag(xml, descriptive_value, tag_name(note.type), attributes)
          end
        end
        private_class_method :write_parallel
      end
    end
  end
end
