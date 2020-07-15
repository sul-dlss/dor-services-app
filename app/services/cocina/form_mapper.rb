# frozen_string_literal: true

module Cocina
  # Maps forms
  class FormMapper
    DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      [].tap do |forms|
        item.descMetadata.ng_xml.xpath('//mods:physicalDescription', mods: DESC_METADATA_NS).each do |form_data|
          form_data.xpath('./mods:form', mods: DESC_METADATA_NS).each do |form_content|
            source = form_content.attribute('authority').value
            type = form_content.attribute('type')&.value
            forms << { value: form_content.content, source: { code: source } }
            forms.last[:type] = type if type.present?
          end

          form_data.xpath('./mods:extent', mods: DESC_METADATA_NS).each do |extent|
            forms << { value: extent.content, type: 'extent' }
          end
        end
      end
    end

    private

    attr_reader :item
  end
end
