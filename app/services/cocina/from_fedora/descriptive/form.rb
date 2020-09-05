# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps relevant mods:physicalDescription from descMetadata to cocina
      class Form
        PHYSICAL_DESCRIPTION_XPATH = '//mods:physicalDescription'
        FORM_XPATH = './mods:form'
        FORM_AUTHORITY_XPATH = './@authority'
        FORM_TYPE_XPATH = './@type'
        EXTENT_XPATH = './mods:extent'

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          [].tap do |forms|
            physical_descriptions.each do |form_data|
              form_data.xpath(FORM_XPATH, mods: DESC_METADATA_NS).each do |form_content|
                forms << {
                  value: form_content.content,
                  type: type_for(form_content),
                  source: source_for(form_content)
                }.reject { |_k, v| v.blank? }
              end

              form_data.xpath(EXTENT_XPATH, mods: DESC_METADATA_NS).each do |extent|
                forms << { value: extent.content, type: 'extent' }
              end
            end
          end
        end

        private

        attr_reader :ng_xml

        def physical_descriptions
          ng_xml.xpath('//mods:physicalDescription', mods: DESC_METADATA_NS)
        end

        def source_for(form)
          { code: form.xpath(FORM_AUTHORITY_XPATH, mods: DESC_METADATA_NS).to_s }
        end

        def type_for(form)
          form.xpath(FORM_TYPE_XPATH, mods: DESC_METADATA_NS).to_s
        end
      end
    end
  end
end
