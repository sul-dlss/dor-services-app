# frozen_string_literal: true

module Cocina
  module ToFedora
    # Finds the correct type of resource
    class ResourceType
      def self.for(object_type:, file_set:)
        new(object_type: object_type, file_set: file_set).find_resource_type
      end

      def initialize(object_type:, file_set:)
        @object_type = object_type
        @file_set = file_set
      end

      def find_resource_type
        case object_type
        when Cocina::Models::Vocab.image, Cocina::Models::Vocab.map, Cocina::Models::Vocab.webarchive_seed
          'image'
        when Cocina::Models::Vocab.book
          Cocina::FileSet.has_any_images?(file_set) ? 'page' : 'object'
        when Cocina::Models::Vocab.three_dimensional
          # if this resource contains no known 3D file extensions, the resource type is file
          Cocina::FileSet.has_any_3d?(file_set) ? '3d' : 'file'
        when Cocina::Models::Vocab.geo
          for_geo
        when Cocina::Models::Vocab.document
          'document'
        when Cocina::Models::Vocab.media
          for_media
        else
          'file'
        end
      end

      private

      attr_reader :object_type, :file_set

      def for_media
        if Cocina::FileSet.has_any_audio?(file_set)
          'audio'
        elsif Cocina::FileSet.has_any_video?(file_set)
          'video'
        else
          'file'
        end
      end

      # This logic has been excerpted from
      # https://github.com/sul-dlss/gis-robot-suite/blob/main/robots/gisAssembly/generate-content-metadata.rb#L30
      def for_geo
        files = file_set.structural.contains
        case ::File.extname(files.first.filename)
        when '.zip', '.TAB', '.tab', '.dat', '.bin', '.xls', '.xlsx', '.tar', '.tgz', '.csv', '.tif', '.json', '.geojson', '.topojson', '.dbf'
          'object'
        when '.png', '.jpg', '.gif', '.jp2'
          'preview'
        when '.xml', '.txt', '.pdf'
          'attachment'
        else
          raise "Unknown resource type for geo: #{file_set.structural.contains.first.filename}"
        end
      end
    end
  end
end
