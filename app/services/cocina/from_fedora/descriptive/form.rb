# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps relevant MODS physicalDescription, typeOfResource and genre from descMetadata to cocina form
      # rubocop:disable Metrics/ClassLength
      class Form
        # NOTE: H2 is the first case of structured form (genre/typeOfResource) values we're implementing
        H2_GENRE_TYPE_PREFIX = 'H2 '

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
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

        attr_reader :ng_xml

        def add_subject_cartographics(forms)
          cartographic_scale.each do |scale|
            next if scale.text.blank?

            forms << {
              value: scale.text,
              type: 'map scale'
            }
          end

          cartographic_projection.each do |projection|
            next if projection.text.blank?

            forms << {
              value: projection.text,
              type: 'map projection'
            }
          end
        end

        def add_genre(forms)
          add_structured_genre(forms) if structured_genre.any?

          basic_genre.each do |type|
            forms << {
              value: type.text,
              type: type['type'] || 'genre'
            }.tap do |item|
              if type[:valueURI]
                item[:uri] = type[:valueURI]
                item[:source] = { code: type[:authority], uri: type[:authorityURI] }.compact
              elsif type[:authority]
                item[:source] = { code: type[:authority] }
              end
            end
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
            forms << {
              "value": type.text,
              "type": 'resource type',
              "source": {
                "value": 'MODS resource types'
              }
            }
          end
        end

        def add_physical_descriptions(forms)
          physical_descriptions.each do |form_data|
            add_forms(forms, form_data)
            add_reformatting_quality(forms, form_data)
            add_media_type(forms, form_data)
            add_extent(forms, form_data)
            add_digital_origin(forms, form_data)
            add_note(forms, form_data)
          end
        end

        def add_note(forms, physical_description)
          physical_description.xpath('mods:note', mods: DESC_METADATA_NS).each do |node|
            forms << {
              note: [{ value: node.content, displayLabel: node['displayLabel'] }.compact]
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
              uri: form_content['valueURI'],
              type: form_content['type'] || 'form',
              source: source_for(form_content).presence
            }.compact
          end
        end

        def physical_descriptions
          ng_xml.xpath('//mods:mods/mods:physicalDescription', mods: DESC_METADATA_NS)
        end

        def source_for(form)
          { code: form['authority'], uri: form['authorityURI'] }.compact
        end

        def type_of_resource
          ng_xml.xpath('//mods:typeOfResource', mods: DESC_METADATA_NS)
        end

        # returns genre at the root and inside subjects excluding structured genres
        def basic_genre
          ng_xml.xpath("//mods:mods/mods:genre[not(@type) or not(starts-with(@type, '#{H2_GENRE_TYPE_PREFIX}'))]", mods: DESC_METADATA_NS)
        end

        # returns structured genres at the root and inside subjects, which are combined to form a single, structured Cocina element
        def structured_genre
          ng_xml.xpath("//mods:mods/mods:genre[@type and starts-with(@type, '#{H2_GENRE_TYPE_PREFIX}')]", mods: DESC_METADATA_NS)
        end

        def cartographic_scale
          ng_xml.xpath('//mods:subject/mods:cartographics/mods:scale', mods: DESC_METADATA_NS)
        end

        def cartographic_projection
          ng_xml.xpath('//mods:subject/mods:cartographics/mods:projection', mods: DESC_METADATA_NS)
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
