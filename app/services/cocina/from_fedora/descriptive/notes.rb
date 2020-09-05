# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps notes
      class Notes
        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          [].tap do |items|
            items << original_url if original_url
            items << abstract if abstract
            items << statement_of_responsibility if statement_of_responsibility
            items << thesis_statement if thesis_statement
            additional_notes.each do |note|
              items << { value: note.content }
            end
          end
        end

        private

        attr_reader :ng_xml

        def abstract
          val = ng_xml.xpath('//mods:abstract', mods: DESC_METADATA_NS).first
          { type: 'summary', value: val.content } if val
        end

        # TODO: Figure out how to encode displayLabel https://github.com/sul-dlss/dor-services-app/issues/849#issuecomment-635713964
        def original_url
          val = ng_xml.xpath('//mods:note[@type="system details"][@displayLabel="Original site"]', mods: DESC_METADATA_NS).first
          { type: 'system details', value: val.content } if val
        end

        def statement_of_responsibility
          val = ng_xml.xpath('//mods:note[@type="statement of responsibility"]', mods: DESC_METADATA_NS).first
          { type: 'statement of responsibility', value: val.content } if val
        end

        def thesis_statement
          val = ng_xml.xpath('//mods:note[@type="thesis"]', mods: DESC_METADATA_NS).first
          { type: 'thesis', value: val.content } if val
        end

        # Returns any notes values that do not include a type attribute
        def additional_notes
          ng_xml.xpath('//mods:note[not(@type)][not(@displayLabel)]', mods: DESC_METADATA_NS)
        end
      end
    end
  end
end
