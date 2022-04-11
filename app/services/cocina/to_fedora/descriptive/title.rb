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
            name_title_vals_index = name_title_vals_index_for(title)

            if title.valueAt
              write_xlink(title: title)
            elsif title.parallelValue.present?
              write_parallel(title: title, title_info_attrs: additional_attrs)
            elsif title.groupedValue.present?
              write_grouped(title: title, title_info_attrs: additional_attrs)
            elsif title.structuredValue.present?
              if name_title_vals_index.present?
                title_value_slice = NameTitleGroup.slice_of_value_or_structured_value(title.to_h)
                my_additional_attrs = additional_attrs.dup
                my_additional_attrs[:nameTitleGroup] = name_title_group_number(title_value_slice)
                write_structured(title: title, title_info_attrs: my_additional_attrs.compact)
              else
                write_structured(title: title, title_info_attrs: additional_attrs.compact)
              end
            elsif title.value
              if name_title_vals_index.present?
                title_value_slice = NameTitleGroup.slice_of_value_or_structured_value(title.to_h)
                my_additional_attrs = additional_attrs.dup
                my_additional_attrs[:nameTitleGroup] = name_title_group_number(title_value_slice)
                write_basic(title: title, title_info_attrs: my_additional_attrs.compact)
              else
                write_basic(title: title, title_info_attrs: additional_attrs.compact)
              end
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
              if name_title_vals_index.present?
                title_value_slice = NameTitleGroup.slice_of_value_or_structured_value(parallel_title.to_h)
                parallel_attrs[:nameTitleGroup] = name_title_group_number(title_value_slice)
              end
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
              write_structured(title: parallel_title, title_info_attrs: parallel_attrs.compact)
            elsif parallel_title.value
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

        # @params [Cocina::Models::Title] titles
        # @return [Hash<Hash, Hash<Hash, Integer>>]
        #   the key is a hash representing a single contributor name, with a key of :value or :structuredValue
        #   the value is a hash, where
        #      the key is a hash representing a single title value, with a key of :value or :structuredValue
        #      the value is the nameTitleGroup number as an Integer
        #   e.g. {{:value=>"James Joyce"}=>{:value=>"Portrait of the artist as a young man"}=>1,
        #   e.g.  {:value=>"Vinsky Cat"}=>{:structuredValue=>[{:value=>"Demanding Food", :type=>"main"},{:value=>"A Cat's Life", :type=>"subtitle"}]}=>2}
        #
        # This complexity is needed for multilingual titles mapping to multilingual names. :-P
        def name_title_vals_index_for(title)
          return nil unless contributors

          title_vals_to_contrib_name_vals = NameTitleGroup.title_vals_to_contrib_name_vals(title, contributors)
          return nil if title_vals_to_contrib_name_vals.blank?

          title_value_slices = NameTitleGroup.value_slices(title)
          title_value_slices.each do |title_value_slice|
            contrib_name_val_slice = title_vals_to_contrib_name_vals[title_value_slice]
            next if contrib_name_val_slice.blank?

            name_title_group = id_generator.next_nametitlegroup
            name_title_vals_index[contrib_name_val_slice] = { title_value_slice => name_title_group }
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

        # @return [Integer] the integer to be used for a nameTitleGroup attribute
        def name_title_group_number(title_value_slice)
          # name_title_vals_index is [Hash<Hash, Hash<Hash, Integer>>]
          #   the key is a hash representing a single contributor name, with a key of :value or :structuredValue
          #   the value is a hash, where
          #      the key is a hash representing a single title value, with a key of :value or :structuredValue
          #      the value is the nameTitleGroup number as an Integer
          #   e.g. {{:value=>"James Joyce"}=>{:value=>"Portrait of the artist as a young man"}=>1}
          #
          # This complexity is needed for multilingual titles mapping to multilingual names. :-P
          name_title_vals_index.values.detect { |hash| hash.key?(title_value_slice) }&.values&.first
        end
      end
    end
  end
end
