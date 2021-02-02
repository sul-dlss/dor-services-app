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
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
        end

        def build
          [].tap do |forms|
            add_genre(forms)
            add_types(forms)
            add_physical_descriptions(forms)
            add_subject_cartographics(forms)
          end
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
          subject_node.xpath('mods:cartographics/mods:scale', mods: DESC_METADATA_NS).each do |scale_node|
            next if scale_node.text.blank?

            carto_forms << {
              value: scale_node.text,
              type: 'map scale'
            }
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

          basic_genre.each do |type|
            forms << {
              value: type.text,
              type: type['type'] || 'genre',
              uri: ValueURI.sniff(type[:valueURI], notifier),
              displayLabel: type[:displayLabel]
            }.tap do |item|
              source = {
                code: Authority.normalize_code(type[:authority], notifier),
                uri: Authority.normalize_uri(type[:authorityURI])
              }.compact
              item[:source] = source if source.present?
            end.compact
          end
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
            if type.text.present?
              forms << {
                value: type.text,
                type: 'resource type',
                source: {
                  value: 'MODS resource types'
                },
                displayLabel: type[:displayLabel].presence
              }.compact
            end

            if type[:manuscript] == 'yes'
              forms << {
                value: 'manuscript',
                source: {
                  value: 'MODS resource types'
                }
              }
            end

            next unless type[:collection] == 'yes'

            forms << {
              value: 'collection',
              source: {
                value: 'MODS resource types'
              }
            }
          end
        end

        def add_physical_descriptions(forms)
          new_forms = []
          physical_descriptions.each do |physical_description_node|
            add_forms(new_forms, physical_description_node)
            add_reformatting_quality(new_forms, physical_description_node)
            add_media_type(new_forms, physical_description_node)
            add_extent(new_forms, physical_description_node)
            add_digital_origin(new_forms, physical_description_node)
            add_note(new_forms, physical_description_node)
            forms.concat(forms_for_display_label(new_forms, physical_description_node))
          end
        end

        def forms_for_display_label(forms, physical_description_node)
          return forms if physical_description_node['displayLabel'].blank?

          if forms.size == 1
            forms.first[:displayLabel] = physical_description_node['displayLabel']
            forms
          else
            [{
              structuredValue: forms,
              displayLabel: physical_description_node['displayLabel']
            }]
          end
        end

        def add_note(forms, physical_description)
          physical_description.xpath('mods:note', mods: DESC_METADATA_NS).each do |node|
            note = {
              value: node.content,
              displayLabel: node['displayLabel'],
              type: node['type']
            }.compact

            forms << {
              note: [note]
            }
          end
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
            forms << { value: extent.content, type: 'extent' }
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

        # returns structured genres at the root and inside subjects, which are combined to form a single, structured Cocina element
        def structured_genre
          resource_element.xpath("mods:genre[@type and starts-with(@type, '#{H2_GENRE_TYPE_PREFIX}')]", mods: DESC_METADATA_NS)
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
