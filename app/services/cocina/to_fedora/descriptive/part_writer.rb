# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps parts from cocina to MODS XML
      class PartWriter
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] part_note
        # @params [IdGenerator] id_generator
        def self.write(xml:, part_note:)
          new(xml: xml, part_note: part_note).write
        end

        def initialize(xml:, part_note:)
          @xml = xml
          @note = part_note
        end

        def write
          if note.groupedValue.present?
            write_grouped_value
          else
            write_structured_value
          end
        end

        private

        attr_reader :xml, :note

        def write_grouped_value
          xml.part do
            attrs = {
              type: find_value(note.groupedValue, 'detail type')
            }.compact

            detail_values = detail_values_for(note)
            if detail_values.present?
              xml.detail attrs do
                detail_values.each { |detail_value| write_part_note_value(detail_value) }
              end
            end
            other_note_values_for(note).each { |other_value| write_part_note_value(other_value) }
            write_extent_for(note)
          end
        end

        def write_structured_value
          xml.part do
            note.structuredValue.each do |note_value|
              attrs = {
                type: find_value(note_value.groupedValue, 'detail type')
              }.compact

              detail_values = detail_values_for(note_value)
              if detail_values.present?
                xml.detail attrs do
                  detail_values.each { |detail_value| write_part_note_value(detail_value) }
                end
              end
              write_part_note_value(note_value) if other_note?(note_value)
              write_extent_for(note_value)
            end
          end
        end

        def write_extent_for(note_value)
          list_value = find_value(note_value.groupedValue, 'list')
          structured_values = note_value.groupedValue&.find { |value| value.structuredValue.present? }&.structuredValue
          if structured_values
            start_value = find_value(structured_values, 'start')
            end_value = find_value(structured_values, 'end')
          end
          return unless list_value || start_value || end_value

          extent_attrs = {
            unit: find_value(note_value.groupedValue, 'extent unit')
          }.compact

          xml.extent extent_attrs do
            xml.list list_value if list_value
            xml.start start_value if start_value
            xml.end end_value if end_value
          end
        end

        def find_value(values, type)
          values&.find { |value| value.type == type }&.value
        end

        def detail_values_for(note_value)
          note_value.groupedValue&.select { |value| %w[number caption title].include?(value.type) }
        end

        def other_note_values_for(note_value)
          note_value.groupedValue&.select { |value| other_note?(value) }
        end

        def other_note?(value)
          %w[text date].include?(value.type)
        end

        def write_part_note_value(value)
          # One of the tag names is "text". Since this is also a method name, normal magic doesn't work.
          xml.method_missing value.type, value.value
        end
      end
    end
  end
end
