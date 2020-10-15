# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps titles from cocina to MODS XML
      class Title
        TAG_NAME = {
          'nonsorting characters' => :nonSort,
          'main title' => :title,
          'subtitle' => :subTitle,
          'part name' => :partName,
          'part number' => :partNumber
        }.freeze
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
              write_structured(title, name_title_group: alt_rep_group)
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

        def write_structured(title, name_title_group:)
          return uniform_title(title, name_title_group: name_title_group) if title.type == 'uniform'
          title_info_attrs = {}
          title_info_attrs[:usage] = 'primary' if title.status == 'primary'
          title_info_attrs[:type] = title.type if title.type

          xml.titleInfo(title_info_attrs) do
            title.structuredValue.each do |component|
              xml.public_send(TAG_NAME.fetch(component.type), component.value) if component.type
            end
          end
        end

        def uniform_title(title, name_title_group:)
          title_info_attrs = { nameTitleGroup: name_title_group}
          title_info_attrs[:usage] = 'primary' if title.status == 'primary'
          title_info_attrs[:type] = title.type if title.type

          title.structuredValue.select {|item| item.type == 'title' }.each do |title|
            xml.titleInfo with_uri_info(title, title_info_attrs) do
              xml.title(title.value)
            end
          end

          title.structuredValue.select {|item| item.type == 'name' }.each do |contributor|
            xml.name with_uri_info(contributor, type: 'personal', nameTitleGroup: name_title_group) do
              xml.namePart(contributor.value)
            end
          end
        end

        def with_uri_info(cocina, xml_attrs)
          xml_attrs[:valueURI] = cocina.uri
          xml_attrs[:authorityURI] = cocina.source&.uri
          xml_attrs[:authority] = cocina.source&.code
          xml_attrs
        end

      end
    end
  end
end
