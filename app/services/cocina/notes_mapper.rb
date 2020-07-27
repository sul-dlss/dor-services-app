# frozen_string_literal: true

module Cocina
  # Maps notes
  class NotesMapper
    DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

    # @param [Dor::Item,Dor::Etd] item
    # @return [Hash] a hash that can be mapped to a cocina model
    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
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

    attr_reader :item

    def abstract
      return if item.descMetadata.abstract.blank?

      @abstract ||= { type: 'summary', value: item.descMetadata.abstract.first }
    end

    # TODO: Figure out how to encode displayLabel https://github.com/sul-dlss/dor-services-app/issues/849#issuecomment-635713964
    def original_url
      val = item.descMetadata.ng_xml.xpath('//mods:note[@type="system details"][@displayLabel="Original site"]', mods: DESC_METADATA_NS).first
      { type: 'system details', value: val.content } if val
    end

    def statement_of_responsibility
      val = item.descMetadata.ng_xml.xpath('//mods:note[@type="statement of responsibility"]', mods: DESC_METADATA_NS).first
      { type: 'statement of responsibility', value: val.content } if val
    end

    def thesis_statement
      val = item.descMetadata.ng_xml.xpath('//mods:note[@type="thesis"]', mods: DESC_METADATA_NS).first
      { type: 'thesis', value: val.content } if val
    end

    # Returns any notes values that do not include a type attribute
    def additional_notes
      item.descMetadata.ng_xml.xpath('//mods:note[not(@type)][not(@displayLabel)]', mods: DESC_METADATA_NS)
    end
  end
end
