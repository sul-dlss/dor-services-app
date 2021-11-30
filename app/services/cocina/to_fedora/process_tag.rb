# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.type attribute to the process tag value
    class ProcessTag
      # TODO: add Software
      MAPPING = {
        Cocina::Models::Vocab.image => 'Image',
        Cocina::Models::Vocab.three_dimensional => '3D',
        Cocina::Models::Vocab.map => 'Map',
        Cocina::Models::Vocab.media => 'Media',
        Cocina::Models::Vocab.manuscript => 'Manuscript',
        Cocina::Models::Vocab.document => 'Document',
        Cocina::Models::Vocab.book => 'Book',
        Cocina::Models::Vocab.object => 'File',
        Cocina::Models::Vocab.webarchive_seed => 'Webarchive Seed'
      }.freeze

      def self.map(type, direction)
        tag = MAPPING.fetch(type, nil)

        return unless tag

        if type == Cocina::Models::Vocab.book
          short_dir = direction == 'right-to-left' ? 'rtl' : 'ltr'
          tag += " (#{short_dir})"
        end

        "Process : Content Type : #{tag}"
      end
    end
  end
end
