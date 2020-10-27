# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps titles from cocina to MODS XML
      class Title
        TAG_NAME = FromFedora::Descriptive::Titles::TYPES.invert.freeze

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
          titles.each_with_index do |title, count|
            if title.parallelValue
              write_parallel(title, alt_rep_group: count)
            elsif title.structuredValue
              write_structured(title, name_title_group: count)
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

        def write_structured(structured_node, name_title_group:)
          title_info_attrs = {} # title_attrs(structured_node)
          # title_info_attrs[:usage] = 'primary' if structured_node.status == 'primary'
          # title_info_attrs[:type] = structured_node.type if structured_node.type

          names = structured_node.structuredValue.group_by { |component| FromFedora::Descriptive::Titles::NAME_TYPES.include? component.type }
          name_title_group += 1 if names[true].present? && name_title_group < 1

          title_info_attrs[:type] = structured_node.type # 'uniform' if structured_node.structuredValue.find { |component| component.type == 'title' }
          title_info_attrs[:usage] = structured_node.status if names[false].present?
          title_info_attrs[:nameTitleGroup] = name_title_group if names[true].present?

          xml.titleInfo(with_uri_info(structured_node, title_info_attrs)) do
            names[false].each do |title|
              title_type = TAG_NAME.fetch(title.type, nil)
              if title_type == 'uniform title'
                title_type = 'title' 
                title_info_attrs.merge(title)
              end
              xml.public_send(title_type, title.value) unless title.note
            end
          end

          if names[true].present?
            name_block = { attributes: {}, values: [] }
            Array(names[true]).each do |name|
              name_block[:attributes].tap do |attrs|
                attrs[:type] = 'personal'
                attrs[:usage] = structured_node.status if structured_node.status
                attrs[:nameTitleGroup] = name_title_group
                attrs[:valueURI] = name.uri if name.uri
                attrs[:authorityURI] = name.source.uri if name.source&.uri
                attrs[:authority] = name.source.code if name.source&.code
              end
              name_block[:values] << { value: name.value, type: name.type }
              # xml.name with_uri_info(structured_node, type: 'personal', nameTitleGroup: name_title_group) do
                # name_attrs = {}
                
                # name_attrs[:type] = name_type if name_type
                # xml.namePart name.value # , with_uri_info(name, nameTitleGroup: name_title_group, type: name_type)
             # end
            end
            xml.name name_block[:attributes] do
              name_block[:values].each do |name|
                name_type = TAG_NAME.fetch(name[:type], nil)
                name_attr = {}
                name_attr[:type] = name_type if name_type
                xml.namePart name[:value], name_attr
              end
            end
          end
        end

        def with_uri_info(cocina, xml_attrs)
          if cocina
            xml_attrs[:valueURI] = cocina.uri
            xml_attrs[:authorityURI] = cocina.source&.uri
            xml_attrs[:authority] = cocina.source&.code
          end
          xml_attrs.compact
        end

        # def title_attrs(node)
        #   {}.tap do |attr|
        #     attr[:usage] = 'primary' if node.status == 'primary'
        #     # attr[:type] = node.type if node.type
        #   end
        # end
      end
    end
  end
end
