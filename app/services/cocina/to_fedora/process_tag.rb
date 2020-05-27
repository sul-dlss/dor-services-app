# frozen_string_literal: true

module Cocina
  module ToFedora
    # This tranforms the DRO.type attribute to the process tag value
    class ProcessTag
      # TODO: add Software
      def self.map(type, direction)
        tag = case type
              when Cocina::Models::Vocab.image
                'Image'
              when Cocina::Models::Vocab.three_dimensional
                '3D'
              when Cocina::Models::Vocab.map
                'Map'
              when Cocina::Models::Vocab.media
                'Media'
              when Cocina::Models::Vocab.manuscript
                'Manuscript'
              when Cocina::Models::Vocab.book
                short_dir = direction == 'right-to-left' ? 'rtl' : 'ltr'
                "Book (#{short_dir})"
              when Cocina::Models::Vocab.document
                'Document'
              when Cocina::Models::Vocab.object
                'File'
              else
                raise "unable to find process tag for #{type}"
              end

        "Process : Content Type : #{tag}"
      end
    end
  end
end
