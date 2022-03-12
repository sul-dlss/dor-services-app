# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Helpers for MODS nameTitleGroups.
      #   MODS titles need to know if they match a contributor and thus need a nameTitleGroup
      #   MODS contributors need to know if they match a title and thus need a nameTitleGroup
      #     If there is a match, the nameTitleGroup number has to be consistent for the matching title(s) and the contributor(s)
      #   We address this with these two public class methods:
      # title_vals_to_contrib_name_vals(title:, contributors:)
      # in_name_title_group?(contributor:, titles:)
      #   and with some public utility class methods
      # contrib_name_value_slices(contributor)
      # value_slices(cocina_desc_value)
      # slice_of_value_or_structured_value(hash)
      class NameTitleGroup
        # When to assign nameTitleGroup to MODS from cocina:
        #   for cocina title of type "uniform",
        #     look for cocina title properties :value or :structuredValue (recurse down through :parallelValue as needed),
        #     and look for associated :note with :type of "associated name" at the level of the non-empty title [value|structuredValue]
        #     The note of type "associated name" will have [value|structuredValue] which will match
        #     [value|structuredValue] for a contributor (possibly after recursing through :parallelValue).
        #   Thus, a title [value|structuredValue] and a contributor [value|structuredValue] are associated in cocina.
        #
        # If those criteria not met in Cocina, do not assign nameTitleGroup in MODS
        #
        # @params [Cocina::Models::Title] title
        # @params [Array<Cocina::Models::Contributor>] contributors
        # @return [Hash<Hash, Hash>] key:  hash of value or structuredValue property for title
        #   value: hash of value or structuredValue property for contributor
        #   e.g. {{:value=>"Portrait of the artist as a young man"}=>{:value=>"James Joyce"}}
        #   e.g. {{:value=>"Portrait of the artist as a young man"}=>{:structuredValue=>[{:value=>"Joyce, James", :type=>"name"},{:value=>"1882-1941", :type=>"life dates"}]}}
        #   e.g. {{:structuredValue=>[{:value=>"Demanding Food", :type=>"main"},{:value=>"A Cat's Life", :type=>"subtitle"}]}=>{:value=>"James Joyce"}}
        #   this complexity is needed for multilingual titles mapping to multilingual names. :-P
        def self.title_vals_to_contrib_name_vals(title, contributors)
          result = {}
          return result if title.blank? || contributors.blank?
          return result if title&.type != 'uniform'

          # pair title value with contributor name value
          title_value_note_slices(title).each do |value_note_slice|
            title_val_slice = slice_of_value_or_structured_value(value_note_slice)
            next if title_val_slice.blank?

            associated_name_note = value_note_slice[:note]&.detect { |note| note[:type] == 'associated name' }
            next if associated_name_note.blank?

            # relevant note will be Array of either
            #   {
            #     value: 'string contributor name',
            #     type: 'associated name'
            #   }
            # OR
            #   {
            #     structuredValue: [ structuredValue contributor name ],
            #     type: 'associated name'
            #   }
            # and we want the hash without the :type attribute
            result[title_val_slice] = slice_of_value_or_structured_value(associated_name_note)
          end
          result
        end

        # @params [Cocina::Models::Contributor] contributor
        # @params [Array<Cocina::Models::Title>] titles
        # @return [boolean] true if contributor part of name title group
        def self.in_name_title_group?(contributor:, titles:)
          return false if contributor&.name.blank? || titles.blank?

          contrib_name_value_slices = contrib_name_value_slices(contributor)
          Array(titles).each do |title|
            name_title_group_names = title_vals_to_contrib_name_vals(title, [contributor])&.values
            name_title_group_names.each do |name|
              return true if contrib_name_value_slices.include?(name)
            end
          end

          false
        end

        # @params [Cocina::Models::Contributor] contributor
        # @return [Hash] where we are only interested in
        #   hashes containing (either :value or :structureValue)
        def self.contrib_name_value_slices(contributor)
          return if contributor&.name.blank?

          slices = []
          Array(contributor.name).each do |contrib_name|
            slices << value_slices(contrib_name)
          end
          slices.flatten
        end

        # @params [Cocina::Models::DescriptiveValue] desc_value
        # @return [Array<Cocina::Models::DescriptiveValue>] where we are only interested in
        #   hashes containing (either :value or :structuredValue)
        def self.value_slices(desc_value)
          slices = []
          desc_value_slice = desc_value.to_h.slice(:value, :structuredValue, :parallelValue)
          if desc_value_slice[:value].present? || desc_value_slice[:structuredValue].present?
            slices << desc_value_slice.select {|_k, value| value.present? }
          elsif desc_value_slice[:parallelValue].present?
            desc_value_slice[:parallelValue].each { |parallel_val| slices << value_slices(parallel_val) }
          end
          # ignoring groupedValue
          slices.flatten
        end
        # private_class_method :value_slices


        # for a given Hash (from a Cocina DescriptiveValue or Title or Name or ...)
        # result will be either
        #   { value: 'string value' }
        # OR
        #   { structuredValue: [ some structuredValue ] }
        def self.slice_of_value_or_structured_value(hash)
          if hash[:value].present?
            hash.slice(:value).select {|_k, value| value.present? }
          elsif hash[:structuredValue].present?
            hash.slice(:structuredValue).select {|_k, value| value.present? }
          end
        end

        # ---------------------- private class methods below ---------------------------------------

        # @params [Cocina::Models::Title] title
        # @return [Array<Cocina::Models::DescriptiveValue>] where we are only interested in
        #   hashes containing (either :value or :structureValue) and :note if present
        def self.title_value_note_slices(title)
          slices = []
          title_slice = title.to_h.slice(:value, :structuredValue, :parallelValue, :note)
          # FIXME: can we simplify to slices << value_slices(title_slice)?
          if title_slice[:value].present? || title_slice[:structuredValue].present?
            slices << title_slice.select {|_k, value| value.present? }
          elsif title_slice[:parallelValue].present?
            title_slice[:parallelValue].each { |parallel_val| slices << title_value_note_slices(parallel_val) }
          end
          # ignoring groupedValue
          slices.flatten
        end
        private_class_method :title_value_note_slices
      end
    end
  end
end
