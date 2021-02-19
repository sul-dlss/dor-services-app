# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps notes from cocina to MODS XML
      class Note
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] notes
        # @params [IdGenerator] id_generator
        def self.write(xml:, notes:, id_generator:)
          new(xml: xml, notes: notes, id_generator: id_generator).write
        end

        def initialize(xml:, notes:, id_generator:)
          @xml = xml
          @notes = notes
          @id_generator = id_generator
        end

        def write
          Array(notes).each do |note|
            if note.parallelValue
              write_parallel(note)
            else
              write_basic(note)
            end
          end
        end

        private

        attr_reader :xml, :notes, :id_generator

        def tag_name(type)
          case type
          when 'summary'
            :abstract
          when 'table of contents'
            :tableOfContents
          when 'target audience'
            :targetAudience
          else
            :note
          end
        end

        def tag(note, tag_name, attributes)
          attributes[:type] = note.type if note.type && [:abstract, :tableOfContents, :targetAudience].exclude?(tag_name)
          value = if note.structuredValue
                    note.structuredValue.map(&:value).join(' -- ')
                  else
                    note.value
                  end
          xml.public_send tag_name, value, attributes
        end

        def write_basic(note)
          tag(note, tag_name(note.type), note_attributes(note))
        end

        def write_parallel(note)
          alt_rep_group = id_generator.next_altrepgroup
          note.parallelValue.each do |parallel_note|
            attributes = { altRepGroup: alt_rep_group }.merge(note_attributes(parallel_note))

            tag(parallel_note, tag_name(note.type), attributes)
          end
        end

        def note_attributes(note)
          {
            'lang' => note.valueLanguage&.code,
            'script' => note.valueLanguage&.valueScript&.code,
            'displayLabel' => note.displayLabel,
            'authority' => note.source&.code,
            'xlink:href' => note.valueAt,
            'ID' => id_for(note)
          }.compact
        end

        def id_for(note)
          Array(note.identifier).find { |identifier| identifier.type == 'anchor' }&.value
        end
      end
    end
  end
end
