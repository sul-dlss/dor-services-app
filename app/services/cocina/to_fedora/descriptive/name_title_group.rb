# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Helpers for working with name title groups.
      class NameTitleGroup
        # @params [Array<Cocina::Models::Contributor>] contributors
        # @params [Cocina::Models::Title] titles
        # @params [Cocina::Models::Contributor, integer, integer] contributor, name index, parallel index
        def self.find_contributor(title:, contributors:)
          title_name_parts = title_name_parts_for(title)
          return [nil, nil, nil] unless title_name_parts

          Array(contributors).each do |contributor|
            Array(contributor.name).each_with_index do |contributor_name, name_index|
              if contributor_name.parallelValue
                contributor_name.parallelValue.each_with_index do |parallel_contributor_name, parallel_index|
                  return [contributor, name_index, parallel_index] if contributor_name_matches?(parallel_contributor_name, title_name_parts)
                end
              elsif contributor_name_matches?(contributor_name, title_name_parts)
                return [contributor, name_index, nil]
              end
            end
          end
          [nil, nil, nil]
        end

        # @params [Cocina::Models::Contributor] contributor
        # @params [Array<Cocina::Models::Title>] titles
        # @params [boolean] true if contributor part of name title group
        def self.part_of_nametitlegroup?(contributor:, titles:)
          Array(titles).any? do |title|
            contributor_match, _name_index, _parallel_index = find_contributor(title: title, contributors: [contributor])
            contributor_match.present?
          end
        end

        def self.title_name_parts_for(title)
          if title.structuredValue
            structured_title = title.structuredValue.find { |check_structured_title| check_structured_title.type == 'name' }
            if structured_title.nil?
              nil
            elsif structured_title.structuredValue
              structured_title.structuredValue
            else
              [structured_title]
            end
          else
            [title]
          end
        end
        private_class_method :title_name_parts_for

        def self.contributor_name_matches?(contributor_name, title_name_parts)
          if contributor_name.structuredValue
            name_matches?(contributor_name.structuredValue, title_name_parts)
          else
            name_matches?([contributor_name], title_name_parts)
          end
        end
        private_class_method :contributor_name_matches?

        def self.name_matches?(contributor_name_parts, title_name_parts)
          contributor_name_parts.all? do |contributor_name_part|
            title_name_parts.any? do |title_name_part|
              title_name_part.value == contributor_name_part.value
            end
          end
        end
        private_class_method :name_matches?
      end
    end
  end
end
