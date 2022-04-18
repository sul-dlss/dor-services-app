# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Helpers for MODS nameTitleGroups.
      class NameTitleGroup
        # @params [Cocina::Models::Contributor] contributor
        # @params [Array<Cocina::Models::Title>] titles
        # @return [boolean] true if contributor part of name title group
        def self.in_name_title_group?(contributor:, titles:)
          return false if contributor&.name.blank? || titles.blank?

          contrib_name_value_slices = Cocina::Models::Builders::NameTitleGroupBuilder.contributor_name_value_slices(contributor)
          Array(titles).each do |title|
            name_title_group_names = Cocina::Models::Builders::NameTitleGroupBuilder.build_title_values_to_contributor_name_values(title)&.values
            name_title_group_names.each do |name|
              return true if contrib_name_value_slices.include?(name)
            end
          end

          false
        end
      end
    end
  end
end
