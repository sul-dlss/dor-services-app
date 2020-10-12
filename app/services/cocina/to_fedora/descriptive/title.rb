# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps titles from cocina to MODS XML
      class Title
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValueRequired>] titles
        def self.write(xml:, titles:)
          new(xml: xml, titles: titles).write
        end

        def initialize(xml:, titles:)
          @xml = xml
          @titles = titles
        end

        def write
          titles.each_with_index do |title, alt_rep_group|
            if title.parallelValue
              write_parallel(title, alt_rep_group: alt_rep_group)
            elsif title.structuredValue
              write_structured(title)
            elsif title.value
              write_basic(title)
            end
          end
        end

        private

        attr_reader :xml, :titles

        def write_basic(title)
          title_info_attrs = {}
          title_info_attrs[:usage] = 'primary' if title.status == 'primary'
          title_info_attrs[:type] = title.type if title.type

          xml.titleInfo(title_info_attrs) do
            xml.title(title.value)
          end
        end

        def write_parallel(title, alt_rep_group:)
          title.parallelValue.each_with_index do |descriptive_value, i|
            title_info_attrs = { altRepGroup: alt_rep_group }
            title_info_attrs[:lang] = descriptive_value.valueLanguage.code if descriptive_value.valueLanguage
            title_info_attrs[:usage] = 'primary' if i.zero?
            title_info_attrs[:type] = 'translated' if i.positive?

            xml.titleInfo(title_info_attrs) do
              descriptive_value.structuredValue&.each do |component|
                xml.public_send(TAG_NAME.fetch(component.type), component.value) if component.type
              end

              xml.title(descriptive_value.value) if descriptive_value.value
            end
          end
        end

        def write_structured(title)
          title_info_attrs = {}
          title_info_attrs[:usage] = 'primary' if title.status == 'primary'
          title_info_attrs[:type] = title.type if title.type

          xml.titleInfo(title_info_attrs) do
            title.structuredValue&.each do |component|
              xml.public_send(TAG_NAME.fetch(component.type), component.value) if component.type
            end
          end
        end
      end
    end
  end
end
