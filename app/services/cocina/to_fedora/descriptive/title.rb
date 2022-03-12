# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps titles from cocina to MODS XML
      #   NOTE: contributors from nameTitleGroups are output here as well;
      #   this allows for consistency of the nameTitleGroup number for the matching title(s) and the contributor(s)
      class Title
        TAG_NAME = FromFedora::Descriptive::Titles::TYPES.invert.merge('activity dates' => 'date').freeze
        NAME_TYPES = ['name', 'forename', 'surname', 'life dates', 'term of address'].freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::Title>] titles
        # @params [Array<Cocina::Models::Contributor>] contributors
        # @params [Hash] additional_attrs for title
        # @params [IdGenerator] id_generator
        def self.write(xml:, titles:, id_generator:, contributors: [], additional_attrs: {})
          new(xml: xml, titles: titles, contributors: contributors, additional_attrs: additional_attrs, id_generator: id_generator).write
        end

        def initialize(xml:, titles:, additional_attrs:, contributors: [], id_generator: {})
          @xml = xml
          @titles = titles
          @contributors = contributors
          @name_title_vals_index = {}
          @additional_attrs = additional_attrs
          @id_generator = id_generator
        end

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def write
          titles.each do |title|
            # name_title_vals_index is a Hash with contrib name value as key,
            #   value a Hash with a key of title value and nameTitleGroup number as hash value
            #   e.g. {"Israel Meir"=>{"Mishnah berurah. English"=>1}, "Israel Meir in Hebrew characters"=>{"Mishnah berurah in Hebrew characters"=>2}}
            #   this complexity is needed for multilingual titles mapping to multilingual names. :-P
            name_title_vals_index = name_title_vals_index_for(title)

            if title.valueAt
              write_xlink(title: title)
            elsif title.parallelValue.present?
              write_parallel(title: title, title_info_attrs: additional_attrs)
            elsif title.groupedValue.present?
              write_grouped(title: title, title_info_attrs: additional_attrs)
            elsif title.structuredValue.present?
              if name_title_vals_index.present?
                title_vals = NameTitleGroup.value_strings(title)
                additional_attrs[:nameTitleGroup] = name_title_group_number(title_vals&.first)
              end
              write_structured(title: title, title_info_attrs: additional_attrs.compact)
            elsif title.value
              additional_attrs[:nameTitleGroup] = name_title_group_number(title.value) if name_title_vals_index.present?
              write_basic(title: title, title_info_attrs: additional_attrs.compact)
            end

            next unless title.type == 'uniform'

            contributors.each do |contributor|
              if NameTitleGroup.in_name_title_group?(contributor: contributor, titles: [title])
                ContributorWriter.write(xml: xml, contributor: contributor, name_title_vals_index: name_title_vals_index, id_generator: id_generator)
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        private

        attr_reader :xml, :titles, :contributors, :name_title_vals_index, :id_generator, :additional_attrs

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

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
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
              elsif parallel_title.type == 'translated'
                parallel_attrs[:type] = 'translated'
              end
            end

            if parallel_title.structuredValue.present?
              if name_title_vals_index.present?
                title_vals = NameTitleGroup.value_strings(title)
                parallel_attrs[:nameTitleGroup] = name_title_group_number(title_vals&.first)
              end
              write_structured(title: parallel_title, title_info_attrs: parallel_attrs.compact)
            elsif parallel_title.value
              parallel_attrs[:nameTitleGroup] = name_title_group_number(parallel_title.value) if name_title_vals_index.present?
              write_basic(title: parallel_title, title_info_attrs: parallel_attrs.compact)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        def write_grouped(title:, title_info_attrs: {})
          title.groupedValue.each { |grouped_title| write_basic(title: grouped_title, title_info_attrs: title_info_attrs) }
        end

        # @return [Hash<String, Hash<String, Integer>] contrib name value as key,
        #   value a Hash with a key of title value and nameTitleGroup number as hash value
        #   e.g. {"Israel Meir"=>{"Mishnah berurah. English"=>1}, "Israel Meir in Hebrew characters"=>{"Mishnah berurah in Hebrew characters"=>2}}
        #   this complexity is needed for multilingual titles mapping to multilingual names. :-P
        def name_title_vals_index_for(title)
          return nil unless contributors

          title_vals_to_contrib_name_vals = NameTitleGroup.title_vals_to_contrib_name_vals(title, contributors)
          return nil if title_vals_to_contrib_name_vals.blank?

          my_title_vals = NameTitleGroup.value_strings(title)
          my_title_vals&.each do |title_val|
            contrib_name_val = title_vals_to_contrib_name_vals[title_val]
            next if contrib_name_val.blank?

            contrib_name_val = contrib_name_val&.first if contrib_name_val.is_a?(Array)

            name_title_group = id_generator.next_nametitlegroup
            name_title_vals_index[contrib_name_val] = { title_val => name_title_group }
          end

          name_title_vals_index
        end

        def write_structured(title:, title_info_attrs: {})
          title_info_attrs = title_info_attrs_for(title).merge(title_info_attrs)
          xml.titleInfo(with_uri_info(title, title_info_attrs)) do
            title_parts = flatten_structured_value(title)
            title_parts_without_names = title_parts_without_names(title_parts)

            title_parts_without_names.each do |title_part|
              title_type = tag_name_for(title_part)
              title_value = title_value_for(title_part, title_type, title)
              xml.public_send(title_type, title_value) if title_part.note.blank?
            end
          end
        end

        def title_value_for(title_part, title_type, title)
          return title_part.value unless title_type == 'nonSort'

          non_sorting_size = [non_sorting_char_count_for(title) - (title_part.value&.size || 0), 0].max
          "#{title_part.value}#{' ' * non_sorting_size}"
        end

        def non_sorting_char_count_for(title)
          non_sort_note = title.note&.find { |note| note.type&.downcase == 'nonsorting character count' }
          return 0 unless non_sort_note

          non_sort_note.value.to_i
        end

        # Flatten the structuredValues into a simple list.
        def flatten_structured_value(title)
          leafs = title.structuredValue.select(&:value)
          nodes = title.structuredValue.select(&:structuredValue).reject { |value| value.type == 'name' }
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

        # @return [Integer] the integer to be used for a nameTitleGroup attrbute
        def name_title_group_number(title_value)
          # name_title_vals_index is [Hash<String, Hash<String, Integer>]
          #   with contrib name value as key,
          #   value a Hash with a key of title value and nameTitleGroup number as hash value
          #   e.g. {"Israel Meir"=>{"Mishnah berurah. English"=>1}, "Israel Meir in Hebrew characters"=>{"Mishnah berurah in Hebrew characters"=>2}}
          #   this complexity is needed for multilingual titles mapping to multilingual names. :-P
          name_title_vals_index.values.detect { |hash| hash.key?(title_value) }&.values&.first
        end
      end
    end
  end
end
