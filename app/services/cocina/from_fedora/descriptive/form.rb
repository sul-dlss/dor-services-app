# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps relevant MODS physicalDescription, typeOfResource and genre from descMetadata to cocina form
      # rubocop:disable Metrics/ClassLength
      class Form
        # NOTE: H2 is the first case of structured form (genre/typeOfResource) values we're implementing
        H2_GENRE_TYPE_PREFIX = 'H2 '

        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:, purl: nil)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
        end

        def build
          forms = []
          add_genre(forms)
          add_types(forms)
          add_physical_descriptions(forms)
          add_subject_cartographics(forms)
          Primary.adjust(forms, 'genre', notifier, match_type: true)
          Primary.adjust(forms, 'resource type', notifier, match_type: true)
        end

        private

        attr_reader :resource_element, :notifier

        def add_subject_cartographics(forms)
          subject_nodes = resource_element.xpath('mods:subject[mods:cartographics]', mods: DESC_METADATA_NS)
          altrepgroup_subject_nodes, other_subject_nodes = AltRepGroup.split(nodes: subject_nodes)

          forms.concat(
            altrepgroup_subject_nodes.map { |parallel_subject_nodes| build_parallel_cartographics(parallel_subject_nodes) } +
            other_subject_nodes.flat_map { |subject_node| build_cartographics(subject_node) }.uniq
          )
        end

        def build_parallel_cartographics(parallel_subject_nodes)
          {
            parallelValue: parallel_subject_nodes.flat_map { |subject_node| build_cartographics(subject_node) }
          }
        end

        def build_cartographics(subject_node)
          carto_forms = []
          subject_node.xpath('mods:cartographics[mods:scale]', mods: DESC_METADATA_NS).each do |carto_node|
            scale_nodes = carto_node.xpath('mods:scale', mods: DESC_METADATA_NS).reject { |scale_node| scale_node.text.blank? }
            if scale_nodes.size == 1
              carto_forms << {
                value: scale_nodes.first.text,
                type: 'map scale'
              }
            elsif scale_nodes.size > 1
              carto_forms << {
                groupedValue: scale_nodes.map { |scale_node| { value: scale_node.text } },
                type: 'map scale'
              }
            end
          end

          subject_node.xpath('mods:cartographics/mods:projection', mods: DESC_METADATA_NS).each do |projection_node|
            next if projection_node.text.blank?

            carto_forms << {
              value: projection_node.text,
              type: 'map projection',
              displayLabel: subject_node['displayLabel'],
              uri: ValueURI.sniff(subject_node['valueURI'], notifier)
            }.tap do |attrs|
              source = {
                code: subject_node['authority'],
                uri: subject_node['authorityURI']
              }.compact
              attrs[:source] = source if source.present?
            end.compact
          end
          carto_forms.uniq
        end

        def add_genre(forms)
          add_structured_genre(forms) if structured_genre.any?

          altrepgroup_genres, other_genre = AltRepGroup.split(nodes: basic_genre)

          other_genre.each { |genre| forms << { type: 'genre' }.merge(build_genre(genre)) }
          altrepgroup_genres.each { |parallel_genres| forms << build_parallel_genre(parallel_genres) }
        end

        def build_genre(genre)
          {
            value: genre.text,
            displayLabel: genre[:displayLabel],
            uri: ValueURI.sniff(genre[:valueURI], notifier)
          }.tap do |attrs|
            source = {
              code: Authority.normalize_code(genre[:authority], notifier),
              uri: Authority.normalize_uri(genre[:authorityURI])
            }.compact
            attrs[:source] = source if source.present?
            attrs[:status] = 'primary' if genre['usage'] == 'primary'
            language_script = LanguageScript.build(node: genre)
            attrs[:valueLanguage] = language_script if language_script
            if genre['type']
              attrs[:note] = [
                {
                  value: genre['type'],
                  type: 'genre type'
                }
              ]
            end
          end.compact
        end

        def build_parallel_genre(genres)
          {
            parallelValue: genres.map { |genre| build_genre(genre) },
            type: 'genre'
          }
        end

        def add_structured_genre(forms)
          # The only use case we're supporting for structured forms at the
          # moment is for H2. Assume these are H2 values.
          forms << {
            type: 'resource type',
            source: {
              value: Cocina::ToFedora::Descriptive::Form::H2_SOURCE_LABEL
            },
            structuredValue: structured_genre.map do |genre|
              {
                value: genre.text,
                type: genre.attributes['type'].value.delete_prefix(H2_GENRE_TYPE_PREFIX)
              }
            end
          }
        end

        def add_types(forms)
          type_of_resource.each do |type|
            forms << resource_type_form(type) if type.text.present?

            forms << manuscript_form if type[:manuscript] == 'yes'

            forms << collection_form if type[:collection] == 'yes'
          end
        end

        def resource_type_form(type)
          {
            value: type.text,
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            },
            displayLabel: type[:displayLabel].presence

          }.tap do |attrs|
            attrs[:status] = 'primary' if type['usage'] == 'primary'
          end.compact
        end

        def manuscript_form
          {
            value: 'manuscript',
            source: {
              value: 'MODS resource types'
            }
          }
        end

        def collection_form
          {
            value: 'collection',
            source: {
              value: 'MODS resource types'
            }
          }
        end

        def add_physical_descriptions(forms)
          physical_descriptions.each do |physical_description_node|
            form_values = []
            add_forms(form_values, physical_description_node)
            add_reformatting_quality(form_values, physical_description_node)
            add_media_type(form_values, physical_description_node)
            add_extent(form_values, physical_description_node)
            add_digital_origin(form_values, physical_description_node)
            notes = physical_description_notes_for(physical_description_node)
            # Depends on how many physicalDescriptions there are or if there is a displayLabel
            if physical_descriptions.size == 1 && form_values.size > 1 && physical_description_node['displayLabel'].nil?
              forms.concat(form_values)
              forms << { note: notes } if notes.present?
            elsif form_values.size == 1
              forms << form_values.first.merge({
                note: notes.presence,
                displayLabel: physical_description_node['displayLabel']
              }.compact)
            else
              forms << {
                groupedValue: form_values,
                note: notes.presence,
                displayLabel: physical_description_node['displayLabel']
              }.compact
            end
          end
        end

        def physical_description_notes_for(physical_description)
          physical_description.xpath('mods:note', mods: DESC_METADATA_NS).map do |node|
            next nil if node.content.blank?

            {
              value: node.content,
              displayLabel: node['displayLabel'],
              type: node['type']
            }.compact
          end.compact
        end

        def add_digital_origin(forms, physical_description)
          physical_description.xpath('mods:digitalOrigin', mods: DESC_METADATA_NS).each do |node|
            forms << {
              value: node.content,
              type: 'digital origin',
              source: { value: 'MODS digital origin terms' }
            }.compact
          end
        end

        def add_extent(forms, physical_description)
          physical_description.xpath('mods:extent', mods: DESC_METADATA_NS).each do |extent|
            forms << {
              value: extent.content,
              type: 'extent'
            }.tap do |form_attrs|
              form_attrs[:note] = [{ type: 'unit', value: extent['unit'] }] if extent['unit']
            end
          end
        end

        def add_media_type(forms, physical_description)
          physical_description.xpath('mods:internetMediaType', mods: DESC_METADATA_NS).each do |node|
            forms << {
              value: node.content,
              type: 'media type',
              source: { value: 'IANA media types' }
            }.compact
          end
        end

        def add_reformatting_quality(forms, physical_description)
          physical_description.xpath('mods:reformattingQuality', mods: DESC_METADATA_NS).each do |node|
            forms << {
              value: node.content,
              type: 'reformatting quality',
              source: { value: 'MODS reformatting quality terms' }
            }.compact
          end
        end

        def add_forms(forms, physical_description)
          physical_description.xpath('mods:form', mods: DESC_METADATA_NS).each do |form_content|
            forms << {
              value: form_content.content,
              uri: ValueURI.sniff(form_content['valueURI'], notifier),
              type: form_content['type'] || 'form',
              source: source_for(form_content).presence
            }.compact
          end
        end

        def physical_descriptions
          resource_element.xpath('mods:physicalDescription', mods: DESC_METADATA_NS)
        end

        def source_for(form)
          {
            code: Authority.normalize_code(form['authority'], notifier),
            uri: Authority.normalize_uri(form['authorityURI'])
          }.compact
        end

        def type_of_resource
          resource_element.xpath('mods:typeOfResource', mods: DESC_METADATA_NS)
        end

        # returns genre at the root and inside subjects excluding structured genres
        def basic_genre
          resource_element.xpath("mods:genre[not(@type) or not(starts-with(@type, '#{H2_GENRE_TYPE_PREFIX}'))]", mods: DESC_METADATA_NS)
        end

        def subject_genre
          resource_element.xpath('mods:subject/mods:genre', mods: DESC_METADATA_NS)
        end

        # returns structured genres at the root and inside subjects, which are combined to form a single, structured Cocina element
        def structured_genre
          resource_element.xpath("mods:genre[@type and starts-with(@type, '#{H2_GENRE_TYPE_PREFIX}')]", mods: DESC_METADATA_NS)
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
