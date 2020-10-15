# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps relevant MODS physicalDescription, typeOfResource and genre from descMetadata to cocina form
      class Form
        PHYSICAL_DESCRIPTION_XPATH = '//mods:physicalDescription'
        FORM_XPATH = './mods:form'
        FORM_AUTHORITY_XPATH = './@authority'
        FORM_TYPE_XPATH = './@type'
        EXTENT_XPATH = './mods:extent'

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
            forms << {
              value: scale.text,
              type: 'map scale'
            }
          end

          cartographic_projection.each do |projection|
            forms << {
              value: projection.text,
              type: 'map projection'
            }
          end
        end

        def add_genre(forms)
          genre.each do |type|
            forms << {
              "value": type.text,
              "type": type['type'] || 'genre'
            }.tap do |item|
              if type[:valueURI]
                item[:uri] = type[:valueURI]
                item[:source] = { code: type[:authority], uri: type[:authorityURI] }
              elsif type[:authority]
                item[:source] = { code: type[:authority] }
              end
            end
          end
        end

        def add_types(forms)
          type_of_resource.each do |type|
            forms << {
              "value": type.text,
              "type": 'resource type',
              "source": {
                "value": 'MODS resource type'
              }
            }
          end
        end

        def add_physical_descriptions(forms)
          physical_descriptions.each do |form_data|
            form_data.xpath(FORM_XPATH, mods: DESC_METADATA_NS).each do |form_content|
              forms << {
                value: form_content.content,
                type: type_for(form_content),
                source: source_for(form_content)
              }.reject { |_k, v| v.blank? }
            end

            form_data.xpath(EXTENT_XPATH, mods: DESC_METADATA_NS).each do |extent|
              forms << { value: extent.content, type: 'extent' }
            end
          end
        end

        def physical_descriptions
          ng_xml.xpath('//mods:physicalDescription', mods: DESC_METADATA_NS)
        end

        def source_for(form)
          { code: form.xpath(FORM_AUTHORITY_XPATH, mods: DESC_METADATA_NS).to_s }
        end

        def type_for(form)
          form.xpath(FORM_TYPE_XPATH, mods: DESC_METADATA_NS).to_s
        end

        def type_of_resource
          ng_xml.xpath('//mods:typeOfResource', mods: DESC_METADATA_NS)
        end

        def genre
          ng_xml.xpath('//mods:genre', mods: DESC_METADATA_NS)
        end

        def cartographic_scale
          ng_xml.xpath('//mods:subject/mods:cartographics/mods:scale', mods: DESC_METADATA_NS)
        end

        def cartographic_projection
          ng_xml.xpath('//mods:subject/mods:cartographics/mods:projection', mods: DESC_METADATA_NS)
        end
      end
    end
  end
end
