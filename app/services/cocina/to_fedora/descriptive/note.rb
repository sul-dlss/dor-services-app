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
          notes.each_with_index do |note, _alt_rep_group|
            xml.abstract note.value
          end
        end

        private

        attr_reader :xml, :notes
      end
    end
  end
end
