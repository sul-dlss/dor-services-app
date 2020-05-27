# frozen_string_literal: true

module Cocina
  module ToFedora
    # This tranforms the DRO.type attribute to the process tag value
    class ProcessTag
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
              else
                Cocina::Models::Vocab.object
              end
        "Process : Content Type : #{tag}"
      end
    end
  end
end
