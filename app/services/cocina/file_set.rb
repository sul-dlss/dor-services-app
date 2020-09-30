# frozen_string_literal: true

module Cocina
  # Methods about Cocina FileSets
  module FileSet
    VALID_THREE_DIMENSION_EXTENSIONS = ['.obj'].freeze
    private_constant :VALID_THREE_DIMENSION_EXTENSIONS

    def self.has_any_images?(file_set)
      has_any_of_type?(file_set, 'image')
    end

    def self.has_any_audio?(file_set)
      has_any_of_type?(file_set, 'audio')
    end

    def self.has_any_video?(file_set)
      has_any_of_type?(file_set, 'video')
    end

    def self.has_any_of_type?(file_set, type)
      file_set.structural.contains.any? { |file| file.hasMimeType.start_with?(type) }
    end

    def self.has_any_3d?(file_set)
      file_set.structural.contains.any? { |file| VALID_THREE_DIMENSION_EXTENSIONS.include?(::File.extname(file.filename)) }
    end
  end
end
