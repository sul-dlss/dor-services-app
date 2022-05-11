# frozen_string_literal: true

module Cocina
  module ToXml
    # This transforms the DRO.type attribute to the
    # Fedora 3 data model contentMetadata#contentType value
    class ContentType
      def self.map(object_type)
        case object_type
        when Cocina::Models::ObjectType.image, Cocina::Models::ObjectType.manuscript
          'image'
        when Cocina::Models::ObjectType.book
          'book'
        when Cocina::Models::ObjectType.map
          'map'
        when Cocina::Models::ObjectType.three_dimensional
          '3d'
        when Cocina::Models::ObjectType.media
          'media'
        when Cocina::Models::ObjectType.webarchive_seed
          'webarchive-seed'
        when Cocina::Models::ObjectType.geo
          'geo'
        when Cocina::Models::ObjectType.document
          'document'
        else
          'file'
        end
      end
    end
  end
end
