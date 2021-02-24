# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps titles from cocina to MODS XML
      class Title
        TAG_NAME = FromFedora::Descriptive::Titles::TYPES.invert.freeze
        NAME_TYPES = ['name', 'forename', 'surname', 'life dates', 'term of address'].freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValueRequired>] titles
        # @params [Array<Cocina::Models::DescriptiveValueRequired>] contributors
        # @params [Hash] additional_attrs for title
        # @params [IdGenerator] id_generator
        def self.write(xml:, titles:, id_generator:, contributors: [], additional_attrs: {})
          new(xml: xml, titles: titles, contributors: contributors, additional_attrs: additional_attrs, id_generator: id_generator).write
        end

        def initialize(xml:, titles:, additional_attrs:, contributors: [], id_generator: {})
          @xml = xml
          @titles = titles
          @contributors = contributors
          @name_title_groups = {}
          @additional_attrs = additional_attrs
          @id_generator = id_generator
        end

        def write
          titles.each do |title|
            if title.valueAt
              write_xlink(title: title)
            elsif title.parallelValue
              write_parallel(title: title, title_info_attrs: additional_attrs)
            else
              title_info_attrs = {
                nameTitleGroup: name_title_group_for(title)
              }.compact.merge(additional_attrs)
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

        attr_reader :xml, :titles, :contributors, :name_title_groups, :id_generator, :additional_attrs

        def write_xlink(title:)
          attrs = { 'xlink:href' => title.valueAt }
          xml.titleInfo attrs
        end

        def write_basic(title:, title_info_attrs: {})
          title_info_attrs = title_info_attrs_for(title).merge(title_info_attrs)

          xml.titleInfo(title_info_attrs) do
            xml.title(title.value)
          end
        end

        # rubocop:disable Metrics/PerceivedComplexity
        def write_parallel(title:, title_info_attrs: {})
          title_alt_rep_group = id_generator.next_altrepgroup

          title.parallelValue.each do |parallel_title|
            parallel_attrs = title_info_attrs.dup
            parallel_attrs[:altRepGroup] = title_alt_rep_group
            parallel_attrs[:lang] = parallel_title.valueLanguage.code if parallel_title.valueLanguage&.code
            if title.type == 'uniform'
              parallel_attrs[:type] = 'uniform'
            elsif parallel_title.type == 'transliterated'
              parallel_attrs[:type] = 'translated'
              parallel_attrs[:transliteration] = parallel_title.standard.value
            elsif title.parallelValue.any? { |parallel_value| parallel_value.status == 'primary' }
              if parallel_title.status == 'primary'
                parallel_attrs[:usage] = 'primary'
              else
                parallel_attrs[:type] = 'translated'
              end
            end
            parallel_attrs[:nameTitleGroup] = name_title_group_for(parallel_title)

            if parallel_title.structuredValue
              write_structured(title: parallel_title, title_info_attrs: parallel_attrs.compact)
            elsif parallel_title.value
              write_basic(title: parallel_title, title_info_attrs: parallel_attrs.compact)
            end
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity

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

        def with_uri_info(cocina, xml_attrs)
          xml_attrs[:valueURI] = cocina.uri
          xml_attrs[:authorityURI] = cocina.source&.uri
          xml_attrs[:authority] = cocina.source&.code
          xml_attrs.compact
        end

        def tag_name_for(title_part)
          return 'title' if title_part.type == 'title'

          TAG_NAME.fetch(title_part.type, nil)
        end

        def title_info_attrs_for(title)
          {
            usage: title.status,
            script: title.valueLanguage&.valueScript&.code,
            lang: title.valueLanguage&.code,
            displayLabel: title.displayLabel,
            valueURI: title.uri,
            authorityURI: title.source&.uri,
            authority: title.source&.code,
            transliteration: title.standard&.value
          }.tap do |attrs|
            if title.type == 'supplied'
              attrs[:supplied] = 'yes'
            elsif title.type != 'transliterated'
              attrs[:type] = title.type
            end
          end.compact
        end
      end
    end
  end
end
