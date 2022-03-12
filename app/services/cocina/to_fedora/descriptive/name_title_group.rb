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
      #   and with this public utility class method
      # value_strings(cocina_descriptive_value)
      class NameTitleGroup
        # When to assign nameTitleGroup to MODS from cocina:
        #  for cocina title of type "uniform", look for:
        # 1) name of status "primary" within a contributor of status "primary" or
        # 2) first name in a contributor with status "primary" or
        # 3) if "appliesTo" value is present in name, the title that matches that value
        # If none of those criteria are met in Cocina, do not assign nameTitleGroup in MODS
        # @params [Cocina::Models::Title] title
        # @params [Array<Cocina::Models::Contributor>] contributors
        # @return [Hash<String, Cocina::Models::DescriptiveValue] title value as key, value a single contributor.name object
        #   e.g.  {"Mishnah berurah. English"=>["Israel Meir"], "Mishnah berurah in Hebrew characters"=>["Israel Meir in Hebrew characters"]}
        #   this complexity is needed for multilingual titles mapping to multilingual names. :-P
        def self.title_vals_to_contrib_name_vals(title, contributors)
          result = {}
          if title.type == 'uniform'
            title_vals = value_strings(title)

            # pair title_values with contributor name with status primary
            primary_contrib_name_vals = value_strings(primary_contributor_name(contributors))
            if primary_contrib_name_vals.present?
              title_vals.each do |title_val|
                result[title_val] = primary_contrib_name_vals.first
              end
              return result unless result.empty?
            end

            # otherwise, pair title_values with contributor name with matching appliesTo property
            title_vals.each do |title_value|
              next if title_value.blank?

              contrib_desc_value = contrib_desc_value_applies_to_title_value(contributors, title_value)
              result[title_value] = value_strings(contrib_desc_value) if contrib_desc_value.present?
            end
          end
          result
        end

        # @params [Cocina::Models::Contributor] contributor
        # @params [Array<Cocina::Models::Title>] titles
        # @return [boolean] true if contributor part of name title group
        def self.in_name_title_group?(contributor:, titles:)
          contributor.name.each do |contrib_name|
            contrib_name_vals = value_strings(contrib_name)
            titles.each do |title|
              name_title_group_names = title_vals_to_contrib_name_vals(title, [contributor])&.values&.flatten
              name_title_group_names.each do |name|
                return true if contrib_name_vals.include?(name)
              end
            end
          end
          false
        end

        # this is also used by Cocina::ToFedora::Descriptive::Title and Cocina::ToFedora::Descriptive::ContributorWriter
        # @params [Cocina::Models::DescriptiveValue] cocina_descriptive_value
        # @return [Array<String>] individual strings assigned from value string properties in (possibly nested) Cocina::Models::DescriptiveValue
        def self.value_strings(cocina_descriptive_value)
          return if cocina_descriptive_value.blank?

          values = []

          # handle single values and arrays
          [cocina_descriptive_value].flatten.each do |cocina_desc_val|
            if cocina_desc_val.value.present?
              values << cocina_desc_val.value
            elsif cocina_desc_val.structuredValue.present?
              values << value_strings(cocina_desc_val.structuredValue.first)
            elsif cocina_desc_val.parallelValue.present?
              cocina_desc_val.parallelValue.each { |parallel_val| values << value_strings(parallel_val) }
            elsif cocina_desc_val.groupedValue.present?
              values << value_strings(cocina_desc_val.groupedValue)
            end
          end

          result = values.flatten.compact
          result unless result.empty?
        end

        # ---------------------- private class methods below ---------------------------------------

        # 1) name of status "primary" within a contributor of status "primary" or
        # 2) first name in (a contributor with status "primary") or
        def self.primary_contributor_name(contributors)
          primary_contributor = contributors.detect { |contrib| contrib.status == 'primary' }
          return unless primary_contributor

          # look for contributor name with status primary within a contributor of status primary
          primary_contributor.name.each do |contrib_name|
            if contrib_name.parallelValue.present?
              contrib_name.parallelValue.each do |parallel_contrib_name|
                return parallel_contrib_name if parallel_contrib_name.status == 'primary'
              end
            elsif contrib_name.status == 'primary' # covers both value and structuredValue cases
              return contrib_name
            end
          end

          primary_contributor.name.first
        end
        private_class_method :primary_contributor_name

        # @params [Array<Cocina::Models::Contributor>] contributors
        # @params [String] title_value to which a contributor.name "appliesTo" should be matched
        # @return [Cocina::Models::DescriptiveValue] the contributor.name or subpart of contributor.name that applies to the title_value
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def self.contrib_desc_value_applies_to_title_value(contributors, title_value)
          contributors.each do |contrib|
            Array(contrib.name).each do |contrib_name|
              if contrib_name.parallelValue.present?
                contrib_name.parallelValue.each do |parallel_contrib_name|
                  title_for_contrib = parallel_contrib_name.appliesTo&.first&.value
                  return parallel_contrib_name if title_for_contrib && title_value == title_for_contrib
                end
              else
                title_for_contrib = contrib_name.appliesTo&.first&.value
                return contrib_name if title_for_contrib && title_value == title_for_contrib
              end
            end
          end
          nil # when this isn't here an empty Array is returned (?)
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        private_class_method :contrib_desc_value_applies_to_title_value
      end
    end
  end
end
