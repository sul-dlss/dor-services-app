# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps titles from cocina to MODS XML
      class Title
        TAG_NAME = FromFedora::Descriptive::Titles::TYPES.invert.freeze
        NAME_TAG_NAME = FromFedora::Descriptive::Contributor::NAME_PART.invert.freeze
        NAME_TYPES = ['name', 'forename', 'surname', 'life dates', 'term of address'].freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValueRequired>] titles
        def self.write(xml:, titles:)
          new(xml: xml, titles: titles).write
        end

        def initialize(xml:, titles:)
          @xml = xml
          @titles = titles
          @alt_rep_group = 0
          @name_title_group = 0
        end

        def write
          titles.each do |title|
            if title.parallelValue
              write_parallel(title: title)
            elsif title.structuredValue
              write_structured(title: title)
            elsif title.value
              write_basic(title: title)
            end
          end
        end

        private

        attr_reader :xml, :titles

        def next_alt_rep_group
          @alt_rep_group += 1
        end

        def next_name_title_group
          @name_title_group += 1
        end

        def write_basic(title:, title_info_attrs: {})
          title_info_attrs = title_info_attrs_for(title).merge(title_info_attrs)

          xml.titleInfo(title_info_attrs) do
            xml.title(title.value)
          end
        end

        def write_parallel(title:)
          title_alt_rep_group = next_alt_rep_group

          title_name_attrs = parallel_has_title_name?(title) ? { altRepGroup: next_alt_rep_group, usage: 'primary' } : {}

          title.parallelValue.each do |parallel_title|
            title_info_attrs = { altRepGroup: title_alt_rep_group }
            title_info_attrs[:lang] = parallel_title.valueLanguage.code if parallel_title.valueLanguage
            if title.type == 'translated'
              if title.status == 'primary'
                title_info_attrs[:usage] = 'primary'
              else
                title_info_attrs[:type] = 'translated'
              end
            elsif title.type == 'uniform'
              title_info_attrs[:type] = 'uniform'
            end

            if parallel_title.structuredValue
              write_structured(title: parallel_title, title_info_attrs: title_info_attrs, title_name_attrs: title_name_attrs)
            elsif parallel_title.value
              write_basic(title: parallel_title, title_info_attrs: title_info_attrs)
            end
          end
        end

        def parallel_has_title_name?(title)
          title.parallelValue.each do |parallel_title|
            next unless parallel_title.structuredValue

            parallel_title.structuredValue.each do |structured_title|
              return true if NAME_TYPES.include?(structured_title.type)
            end
          end
          false
        end

        def write_structured(title:, title_info_attrs: {}, title_name_attrs: {})
          title_names = title.structuredValue.select { |structured_title| NAME_TYPES.include?(structured_title.type) }
          name_title_group = next_name_title_group if title_names.present?

          title_info_attrs = title_info_attrs_for(title, name_title_group: name_title_group).merge(title_info_attrs)

          xml.titleInfo(with_uri_info(title, title_info_attrs)) do
            title.structuredValue.reject { |structured_title| NAME_TYPES.include?(structured_title.type) }.each do |title_part|
              title_type = tag_name_for(title_part)
              xml.public_send(title_type, title_part.value) unless title_part.note
            end
          end

          write_title_names(title_names, name_title_group, title, title_name_attrs) if title_names.present?
        end

        def write_title_names(title_names, name_title_group, title, title_name_attrs)
          title_name_with_authority = title_names.find { |title_name| title_name.uri || title_name.source }

          title_name_attrs = name_attrs_for(title_name_with_authority || title_names.first, name_title_group, title).merge(title_name_attrs)

          xml.name title_name_attrs do
            title_names.each do |title_name|
              name_type = NAME_TAG_NAME.fetch(title_name[:type], nil)
              name_attrs = {}
              name_attrs[:type] = name_type if name_type
              xml.namePart title_name[:value], name_attrs
            end
          end
        end

        def with_uri_info(cocina, xml_attrs)
          xml_attrs[:valueURI] = cocina.uri
          xml_attrs[:authorityURI] = cocina.source&.uri
          xml_attrs[:authority] = cocina.source&.code
          xml_attrs.compact
        end

        def name_attrs_for(title_name, name_title_group, title)
          {}.tap do |attrs|
            attrs[:type] = 'personal'
            attrs[:usage] = title_name.status if title_name.status
            attrs[:usage] = title.status if title.type == 'uniform' && title.status
            attrs[:nameTitleGroup] = name_title_group
            attrs[:valueURI] = title_name.uri if title_name.uri
            attrs[:authorityURI] = title_name.source.uri if title_name.source&.uri
            attrs[:authority] = title_name.source.code if title_name.source&.code
          end
        end

        def tag_name_for(title_part)
          return 'title' if title_part.type == 'title'

          TAG_NAME.fetch(title_part.type, nil)
        end

        def title_info_attrs_for(title, name_title_group: nil)
          {}.tap do |attrs|
            attrs[:type] = title.type if title.type
            attrs[:usage] = title.status if title.status
            attrs[:nameTitleGroup] = name_title_group if name_title_group
            attrs[:script] = title.valueLanguage.valueScript.code if title.valueLanguage&.valueScript&.code
          end
        end
      end
    end
  end
end
