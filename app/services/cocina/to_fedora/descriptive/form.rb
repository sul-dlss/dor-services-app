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

        def physical_description?(form, type: nil)
          (form.note.present? && form.type != 'genre') ||
            PHYSICAL_DESCRIPTION_TAG.key?(type) ||
            PHYSICAL_DESCRIPTION_TAG.key?(form.type) ||
            PHYSICAL_DESCRIPTION_TAG.key?(form.groupedValue&.first&.type) ||
            (form.parallelValue.present? && physical_description?(form.parallelValue.first))
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
          parallel_physical_descr_forms, other_physical_descr_forms = Array(forms).select { |form| physical_description?(form) }.partition(&:parallelValue)
          write_physical_description(other_physical_descr_forms)

          parallel_physical_descr_forms.each do |parallel_physical_descr_form|
            alt_rep_group = id_generator.next_altrepgroup
            write_physical_description(parallel_physical_descr_form.parallelValue, alt_rep_group: alt_rep_group, display_label: parallel_physical_descr_form.displayLabel,
                                                                                   form: parallel_physical_descr_form)
          end
        end

        def write_physical_description(physical_descr_forms, alt_rep_group: nil, display_label: nil, form: nil)
          grouped_forms = []
          # Each of these are its own physicalDescription
          simple_forms = []
          # These all get grouped together to form a single physicalDescription.
          other_forms = []
          other_notes = []
          Array(physical_descr_forms).select { |physical_descr_form| physical_description?(physical_descr_form, type: form&.type) }.each do |physical_descr_form|
            if physical_descr_form.groupedValue
              grouped_forms << physical_descr_form
            elsif merge_form?(physical_descr_form, display_label) || alt_rep_group
              simple_forms << physical_descr_form
            else
              other_notes << physical_descr_form if physical_descr_form.note
              other_forms << physical_descr_form if physical_descr_form.value
            end
          end

          write_basic_physical_description(other_forms, other_notes, alt_rep_group: alt_rep_group, form: form) unless other_forms.empty?
          simple_forms.each { |simple_form| write_basic_physical_description([simple_form], [simple_form], alt_rep_group: alt_rep_group, form: form) }
          grouped_forms.each { |grouped_form| write_grouped_physical_description(grouped_form, alt_rep_group: alt_rep_group, form: form) }
        end

        def merge_form?(form, display_label)
          form.value && (Array(form.note).any? { |note| note.type != 'unit' } || form.displayLabel || display_label)
        end

        def write_basic_physical_description(forms, note_forms, alt_rep_group: nil, form: nil)
          physical_description_attrs = {
            displayLabel: forms.first.displayLabel || form&.displayLabel,
            altRepGroup: alt_rep_group
          }.compact

          xml.physicalDescription physical_description_attrs do
            write_physical_description_form_values(forms, form: form)
            note_forms.each { |note_form| write_notes(note_form) if note_form.note }
          end
        end

        def write_grouped_physical_description(grouped_form, alt_rep_group: nil, form: nil)
          physical_description_attrs = {
            displayLabel: grouped_form.displayLabel || form&.displayLabel,
            altRepGroup: alt_rep_group
          }.compact

          xml.physicalDescription physical_description_attrs do
            write_physical_description_form_values(grouped_form.groupedValue, form: form)
            write_notes(grouped_form)
          end
        end

        def write_physical_description_form_values(form_values, form: nil)
          form_values.each do |form_value|
            form_type = form_value.type || form&.type
            attributes = {
              unit: unit_for(form_value)
            }.tap do |attrs|
              attrs[:type] = form_type if PHYSICAL_DESCRIPTION_TAG.fetch(form_type) == :form && form_type != 'form'
            end.compact

            xml.public_send PHYSICAL_DESCRIPTION_TAG.fetch(form_type), form_value.value, attributes.merge(uri_attrs(form_value)).merge(uri_attrs(form))
          end
        end

        def write_notes(form)
          Array(form.note).reject { |note| note.type == 'unit' }.each do |note|
            attributes = {
              displayLabel: note.displayLabel,
              type: note.type
            }.compact
            xml.note note.value, attributes
          end
        end

        def write_basic(form, is_manuscript: false, is_collection: false, alt_rep_group: nil)
          return nil if form.source&.value&.match?(/DataCite/i)

          attributes = form_attributes(form, alt_rep_group)

          case form.type
          when 'resource type'
            attributes[:manuscript] = 'yes' if is_manuscript
            attributes[:collection] = 'yes' if is_collection
            xml.typeOfResource form.value, attributes
          when 'map scale', 'map projection'
            # do nothing, these end up in subject/cartographics
          else # genre
            xml.genre form.value, attributes.merge({ type: genre_type_for(form) }.compact).merge(uri_attrs(form))
          end
        end

        def unit_for(form)
          Array(form.note).find { |note| note.type == 'unit' }&.value
        end

        def genre_type_for(form)
          Array(form.note).find { |note| note.type == 'genre type' }&.value
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

        def uri_attrs(form)
          return {} if form.nil?

          {
            valueURI: form.uri,
            authorityURI: form.source&.uri,
            authority: form.source&.code
          }.compact
        end
      end
    end
  end
end
