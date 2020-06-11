# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.type attribute to the
    # Fedora 3 data model contentMetadata#contentType value
    class ContentType
      def self.map(object_type)
        case object_type
        when Cocina::Models::Vocab.image, Cocina::Models::Vocab.manuscript
          'image'
        when Cocina::Models::Vocab.book
          'book'
        when Cocina::Models::Vocab.map
          'map'
        when Cocina::Models::Vocab.three_dimensional
          '3d'
        when Cocina::Models::Vocab.media
          'media'
        when Cocina::Models::Vocab.webarchive_seed
          'webarchive-seed'
        when Cocina::Models::Vocab.geo
          'geo'
        when Cocina::Models::Vocab.document
          'document'
        else
          'file'
        end
      end
    end
  end
end
