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
          xml.part do
            attrs = {
              type: note_type
            }.compact

            if detail_values.present?
              xml.detail attrs do
                detail_values.each { |detail_value| write_part_note_value(detail_value) }
              end
            end
            other_note_values.each { |other_value| write_part_note_value(other_value) }
            write_extent
          end
        end

        private

        attr_reader :xml, :note

        def write_extent
          list = note.groupedValue.find { |value| value.type == 'list' }&.value
          return unless list

          extent_attrs = {
            unit: note.groupedValue.find { |value| value.type == 'extent unit' }&.value
          }.compact
          xml.extent extent_attrs do
            xml.list list
          end
        end

        def note_type
          note.groupedValue.find { |value| value.type == 'detail type' }&.value
        end

        def detail_values
          @detail_values ||= note.groupedValue.select { |value| %w[number caption title].include?(value.type) }
        end

        def other_note_values
          @other_note_values ||= note.groupedValue.select { |value| %w[text date].include?(value.type) }
        end

        def write_part_note_value(value)
          # One of the tag names is "text". Since this is also a method name, normal magic doesn't work.
          xml.method_missing value.type, value.value
        end
      end
    end
  end
end
