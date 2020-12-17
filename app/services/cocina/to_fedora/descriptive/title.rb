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
        # @params [Array<Cocina::Models::DescriptiveValueRequired>] contributors
        # @params [IdGenerator] id_generator
        def self.write(xml:, titles:, contributors:, id_generator:)
          new(xml: xml, titles: titles, contributors: contributors, id_generator: id_generator).write
        end

        def initialize(xml:, titles:, contributors:, id_generator:)
          @xml = xml
          @titles = titles
          @contributors = contributors
          @name_title_groups = {}
          @id_generator = id_generator
        end

        def write
          titles.each do |title|
            if title.parallelValue
              write_parallel(title: title)
            else
              title_info_attrs = {
                nameTitleGroup: name_title_group_for(title)
              }.compact
              if title.structuredValue
                write_structured(title: title, title_info_attrs: title_info_attrs)
              elsif title.value
                write_basic(title: title, title_info_attrs: title_info_attrs)
              end
            end
          end

          name_title_groups.each_pair do |contributor, name_title_group_indexes|
            ContributorWriter.write(xml: xml, contributor: contributor, name_title_group_indexes: name_title_group_indexes, id_generator: id_generator)
          end
        end

        private

        attr_reader :xml, :titles, :contributors, :name_title_groups, :id_generator

        def write_basic(title:, title_info_attrs: {})
          title_info_attrs = title_info_attrs_for(title).merge(title_info_attrs)

          xml.titleInfo(title_info_attrs) do
            xml.title(title.value)
          end
        end

        def write_parallel(title:)
          title_alt_rep_group = id_generator.next_altrepgroup

          title.parallelValue.each do |parallel_title|
            title_info_attrs = { altRepGroup: title_alt_rep_group }
            title_info_attrs[:lang] = parallel_title.valueLanguage.code if parallel_title.valueLanguage&.code
            if title.type == 'translated'
              if title.status == 'primary'
                title_info_attrs[:usage] = 'primary'
              else
                title_info_attrs[:type] = 'translated'
              end
            elsif title.type == 'uniform'
              title_info_attrs[:type] = 'uniform'
            elsif parallel_title.type == 'transliterated'
              title_info_attrs[:type] = 'translated'
              title_info_attrs[:transliteration] = parallel_title.standard.value
            end

            title_info_attrs[:nameTitleGroup] = name_title_group_for(parallel_title)

            if parallel_title.structuredValue
              write_structured(title: parallel_title, title_info_attrs: title_info_attrs.compact)
            elsif parallel_title.value
              write_basic(title: parallel_title, title_info_attrs: title_info_attrs.compact)
            end
          end
        end

        def name_title_group_for(title)
          return nil unless contributors

          contributor, name_index, parallel_index = NameTitleGroup.find_contributor(title: title, contributors: contributors)

          return nil unless contributor

          name_title_group = id_generator.next_nametitlegroup
          name_title_groups[contributor] ||= {}
          if parallel_index
            name_title_groups[contributor][name_index] ||= {}
            name_title_groups[contributor][name_index][parallel_index] = name_title_group
          else
            name_title_groups[contributor][name_index] = name_title_group
          end
          name_title_group
        end

        def write_structured(title:, title_info_attrs: {})
          title_info_attrs = title_info_attrs_for(title).merge(title_info_attrs)

          xml.titleInfo(with_uri_info(title, title_info_attrs)) do
            title_parts = flatten_structured_value(title)
            title_parts_without_names = title_parts_without_names(title_parts)

            title_parts_without_names.each do |title_part|
              title_type = tag_name_for(title_part)
              xml.public_send(title_type, title_part.value) unless title_part.note
            end
          end
        end

        # Flatten the structuredValues into a simple list.
        def flatten_structured_value(title)
          leafs = title.structuredValue.select(&:value)
          nodes = title.structuredValue.select(&:structuredValue)
          leafs + nodes.flat_map { |node| flatten_structured_value(node) }
        end

        # Filter out name types
        def title_parts_without_names(parts)
          parts.reject { |structured_title| NAME_TYPES.include?(structured_title.type) }
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

        def title_info_attrs_for(title)
          {}.tap do |attrs|
            attrs[:type] = title.type
            attrs[:usage] = title.status
            attrs[:script] = title.valueLanguage&.valueScript&.code
            attrs[:displayLabel] = title.displayLabel
          end.compact
        end
      end
    end
  end
end
