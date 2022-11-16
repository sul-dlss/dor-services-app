# frozen_string_literal: true

module Cocina
  # Validates only only file content types have filenames with hierarchy (e.g., foo/bar.txt)
  class FileHierarchyValidator
    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    attr_reader :error

    # @return [Boolean] false if file hierarchy is present, but not file content type
    def valid?
      @error = 'File hierarchy present, but content type is not file' if file_hierarchy_present? && !file_content_type?
      @error.nil?
    end

    private

    attr_reader :cocina_object

    def file_hierarchy_present?
      cocina_object.structural.contains.any? { |file_set| file_set.structural.contains.any? { |file| file.filename.include?('/') } }
    end

    def file_content_type?
      Cocina::ToXml::ContentType.map(cocina_object.type) == 'file'
    end
  end
end
