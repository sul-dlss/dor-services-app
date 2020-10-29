# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps titles from cocina to MODS XML
      class Title
        TAG_NAME = FromFedora::Descriptive::Titles::TYPES.invert.freeze
        NAME_TYPES = ['person', 'forename', 'surname', 'life dates'].freeze

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
            @title = title
            @title_group = count
            if title.parallelValue
              write_parallel(alt_rep_group: count)
            elsif title.structuredValue
              write_structured
            elsif title.value
              write_basic
            end
          end
        end

        private

        attr_reader :xml, :titles, :title, :title_group

        def write_basic
          title_info_attrs = {}
          title_info_attrs[:usage] = 'primary' if title.status == 'primary'
          title_info_attrs[:type] = title.type if title.type

          xml.titleInfo(title_info_attrs) do
            xml.title(title.value)
          end
        end

        def write_parallel(alt_rep_group:)
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

        def write_structured
          xml.titleInfo(with_uri_info(title, title_attrs)) do
            sturctured_titles.each do |title|
              title_type = TAG_NAME.fetch(title.type, nil)
              if title_type == 'uniform title'
                title_type = 'title'
                title_attrs.merge(title)
              end
              xml.public_send(title_type, title.value) unless title.note
            end
          end

          return unless names

          xml.name name_attrs do
            format_name(name_with_authority) if name_with_authority
            basic_names&.each do |name|
              format_name(name)
            end
          end
        end

        def format_name(name)
          name_type = TAG_NAME.fetch(name[:type], nil)
          name_attr = {}
          name_attr[:type] = name_type if name_type
          xml.namePart name[:value], name_attr
        end

        def with_uri_info(cocina, xml_attrs)
          xml_attrs[:valueURI] = cocina.uri
          xml_attrs[:authorityURI] = cocina.source&.uri
          xml_attrs[:authority] = cocina.source&.code
          xml_attrs.compact
        end

        def components
          @components ||= title.structuredValue.group_by { |component| NAME_TYPES.include? component.type }
        end

        def names
          return unless components[true]

          @names ||= components[true].group_by { |name| FromFedora::Descriptive::Titles::PERSON_TYPE == name.type }
        end

        def basic_names
          names[false]
        end

        def name_with_authority
          return unless names[true]

          Array(names[true]).first
        end

        def name_attrs
          {}.tap do |attrs|
            attrs[:type] = 'personal'
            attrs[:usage] = title.status if title.status
            attrs[:nameTitleGroup] = name_title_group
            attrs[:valueURI] = name_with_authority.uri if name_with_authority
            attrs[:authorityURI] = name_with_authority.source.uri if name_with_authority&.source&.uri
            attrs[:authority] = name_with_authority.source.code if name_with_authority&.source&.code
          end
        end

        def sturctured_titles
          components[false]
        end

        def name_title_group
          return unless names

          return title_group + 1 if title_group < 1

          title_group
        end

        def title_attrs
          {}.tap do |attrs|
            attrs[:type] = title.type
            attrs[:usage] = title.status
            attrs[:nameTitleGroup] = name_title_group if name_title_group
          end
        end
      end
    end
  end
end
