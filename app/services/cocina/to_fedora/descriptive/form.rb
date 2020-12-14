# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps forms from cocina to MODS XML
      class Form
        # NOTE: H2 is the first case of structured form values we're implementing
        H2_SOURCE_LABEL = 'Stanford self-deposit resource types'
        PHYSICAL_DESCRIPTION_TAG = {
          'reformatting quality' => :reformattingQuality,
          'form' => :form,
          'media type' => :internetMediaType,
          'extent' => :extent,
          'digital origin' => :digitalOrigin,
          'media' => :form,
          'carrier' => :form
        }.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] forms
        def self.write(xml:, forms:)
          new(xml: xml, forms: forms).write
        end

        def initialize(xml:, forms:)
          @xml = xml
          @forms = forms
        end

        def write
          other_forms = Array(forms).reject { |form| physical_description_member?(form) || manuscript?(form) || collection?(form) }
          is_manuscript = Array(forms).any? { |form| manuscript?(form) }
          is_collection = Array(forms).any? { |form| collection?(form) }

          other_forms.each do |form|
            if form.structuredValue
              write_structured(form)
            elsif form.value
              write_basic(form, is_manuscript: is_manuscript, is_collection: is_collection)
            end
          end

          physical_description_forms = Array(forms).select { |form| physical_description_member?(form) }
          write_physical_description(physical_description_forms)
        end

        private

        attr_reader :xml, :forms

        def physical_description_member?(form)
          form.note.present? || PHYSICAL_DESCRIPTION_TAG.keys.include?(form.type)
        end

        def manuscript?(form)
          form.to_h == { value: 'manuscript', source: { value: 'MODS resource types' } }
        end

        def collection?(form)
          form.to_h == { value: 'collection', source: { value: 'MODS resource types' } }
        end

        def write_physical_description(forms)
          return if forms.empty?

          xml.physicalDescription do
            forms.each do |form|
              if form.note
                form.note.each do |val|
                  attributes = {}
                  attributes[:displayLabel] = val.displayLabel
                  xml.note val.value, attributes.compact
                end
              else
                attributes = {}
                attributes[:type] = form.type if PHYSICAL_DESCRIPTION_TAG.fetch(form.type) == :form && form.type != 'form'
                xml.public_send PHYSICAL_DESCRIPTION_TAG.fetch(form.type), form.value, with_uri_info(form, attributes)
              end
            end
          end
        end

        def write_basic(form, is_manuscript: false, is_collection: false)
          return nil if form.source&.value&.match?(/DataCite/i)
          return note(form) if form.note

          attributes = {}.tap do |attrs|
            attrs[:displayLabel] = form.displayLabel
          end.compact

          case form.type
          when 'resource type'
            attributes[:manuscript] = 'yes' if is_manuscript
            attributes[:collection] = 'yes' if is_collection
            xml.typeOfResource form.value, attributes
          when 'map scale', 'map projection'
            # do nothing, these end up in subject/cartographics
          when 'genre'
            xml.genre form.value, with_uri_info(form, attributes)
          else
            xml.genre form.value, with_uri_info(form, attributes.merge(type: form.type))
          end
        end

        def write_structured(form)
          # The only use case we're supporting for structured forms at the
          # moment is for H2. Short-circuit if that's not what we get.
          return if form.source.value != H2_SOURCE_LABEL

          form.structuredValue.each do |genre|
            xml.genre genre.value, type: "H2 #{genre.type}"
          end
        end

        def with_uri_info(cocina, xml_attrs)
          xml_attrs[:valueURI] = cocina.uri
          xml_attrs[:authorityURI] = cocina.source&.uri
          xml_attrs[:authority] = cocina.source&.code
          xml_attrs.compact
        end
      end
    end
  end
end
