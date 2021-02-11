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
          'carrier' => :form,
          'material' => :form,
          'technique' => :form
        }.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] forms
        # @params [IdGenerator] id_generator
        def self.write(xml:, forms:, id_generator:)
          new(xml: xml, forms: forms, id_generator: id_generator).write
        end

        def initialize(xml:, forms:, id_generator:)
          @xml = xml
          @forms = forms
          @id_generator = id_generator
        end

        def write
          other_forms = Array(forms).reject { |form| physical_description?(form) || manuscript?(form) || collection?(form) }
          is_manuscript = Array(forms).any? { |form| manuscript?(form) }
          is_collection = Array(forms).any? { |form| collection?(form) }

          if other_forms.present?
            write_other_forms(other_forms, is_manuscript, is_collection)
          else
            write_attributes_only(is_manuscript, is_collection)
          end

          write_physical_descriptions
        end

        private

        attr_reader :xml, :forms, :id_generator

        def physical_description?(form)
          form.note.present? || PHYSICAL_DESCRIPTION_TAG.keys.include?(form.type) || PHYSICAL_DESCRIPTION_TAG.keys.include?(form.structuredValue&.first&.type)
        end

        def manuscript?(form)
          form.to_h == { value: 'manuscript', source: { value: 'MODS resource types' } }
        end

        def collection?(form)
          form.to_h == { value: 'collection', source: { value: 'MODS resource types' } }
        end

        def write_other_forms(forms, is_manuscript, is_collection)
          forms.each do |form|
            if form.parallelValue
              write_parallel_forms(form, is_manuscript, is_collection)
            else
              write_form(form, is_manuscript, is_collection)
            end
          end
        end

        def write_parallel_forms(form, is_manuscript, is_collection)
          alt_rep_group = id_generator.next_altrepgroup
          form.parallelValue.each { |form_value| write_form(form_value, is_manuscript, is_collection, alt_rep_group: alt_rep_group) }
        end

        def write_form(form, is_manuscript, is_collection, alt_rep_group: nil)
          if form.structuredValue
            write_structured(form)
          elsif form.value
            write_basic(form, is_manuscript: is_manuscript, is_collection: is_collection, alt_rep_group: alt_rep_group)
          end
        end

        def write_physical_descriptions
          Array(forms).select { |form| physical_description?(form) }.each do |form|
            if form.structuredValue
              write_structured_physical_description(form)
            else
              write_basic_physical_description(form)
            end
          end
        end

        def write_basic_physical_description(form)
          physical_description_attrs = {
            displayLabel: form.displayLabel
          }.compact

          xml.physicalDescription physical_description_attrs do
            write_physical_description_form_values([form])
            write_notes(form)
          end
        end

        def write_structured_physical_description(form)
          physical_description_attrs = {
            displayLabel: form.displayLabel
          }.compact

          xml.physicalDescription physical_description_attrs do
            write_physical_description_form_values(form.structuredValue)
            write_notes(form)
          end
        end

        def write_physical_description_form_values(form_values)
          form_values.each do |form|
            attributes = {}
            attributes[:type] = form.type if PHYSICAL_DESCRIPTION_TAG.fetch(form.type) == :form && form.type != 'form'
            xml.public_send PHYSICAL_DESCRIPTION_TAG.fetch(form.type), form.value, with_uri_info(form, attributes)
          end
        end

        def write_notes(form)
          Array(form.note).each do |val|
            attributes = {
              displayLabel: val.displayLabel,
              type: val.type
            }.compact
            xml.note val.value, attributes
          end
        end

        def write_basic(form, is_manuscript: false, is_collection: false, alt_rep_group: nil)
          return nil if form.source&.value&.match?(/DataCite/i)
          return note(form) if form.note

          attributes = form_attributes(form, alt_rep_group)

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

        def form_attributes(form, alt_rep_group)
          {
            altRepGroup: alt_rep_group,
            displayLabel: form.displayLabel,
            usage: form.status,
            lang: form.valueLanguage&.code,
            script: form.valueLanguage&.valueScript&.code
          }.compact
        end

        def write_attributes_only(is_manuscript, is_collection)
          return unless is_manuscript || is_collection

          attributes = {}
          attributes[:manuscript] = 'yes' if is_manuscript
          attributes[:collection] = 'yes' if is_collection
          xml.typeOfResource(nil, attributes)
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
