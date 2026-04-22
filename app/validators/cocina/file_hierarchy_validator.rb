# frozen_string_literal: true

module Cocina
  # Validates only object and geo Cocina types have filenames with hierarchy (e.g., foo/bar.txt)
  class FileHierarchyValidator
    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    attr_reader :error

    # @return [Boolean] false if file hierarchy is present, but Cocina type is not object or geo
    def valid?
      if file_hierarchy_present? && !permitted_type?
        @error = 'File hierarchy present, but content type is not file or geo'
      end
      @error.nil?
    end

    private

    attr_reader :cocina_object

    def file_hierarchy_present?
      return false unless cocina_object.structural

      cocina_object.structural.contains.any? do |file_set|
        file_set.structural.contains.any? do |file|
          file.filename.include?('/')
        end
      end
    end

    # object and geo types may have filenames with hierarchy, but other Cocina types do not
    def permitted_type?
      [Cocina::Models::ObjectType.geo, Cocina::Models::ObjectType.object].include?(cocina_object.type)
    end
  end
end
