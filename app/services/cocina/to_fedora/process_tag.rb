# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.type attribute to the process tag value
    class ProcessTag
      # TODO: add Software
      MAPPING = {
        Cocina::Models::ObjectType.image => 'Image',
        Cocina::Models::ObjectType.three_dimensional => '3D',
        Cocina::Models::ObjectType.map => 'Map',
        Cocina::Models::ObjectType.media => 'Media',
        Cocina::Models::ObjectType.manuscript => 'Manuscript',
        Cocina::Models::ObjectType.document => 'Document',
        Cocina::Models::ObjectType.book => 'Book',
        Cocina::Models::ObjectType.object => 'File',
        Cocina::Models::ObjectType.webarchive_seed => 'Webarchive Seed'
      }.freeze

      def self.map(type, direction)
        tag = MAPPING.fetch(type, nil)

        return unless tag

        if type == Cocina::Models::ObjectType.book
          short_dir = direction == 'right-to-left' ? 'rtl' : 'ltr'
          tag += " (#{short_dir})"
        end

        "Process : Content Type : #{tag}"
      end
    end
  end
end
