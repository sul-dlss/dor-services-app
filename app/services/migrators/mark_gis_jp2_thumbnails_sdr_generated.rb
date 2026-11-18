# frozen_string_literal: true

module Migrators
  # Marks the JP2 thumbnails that gis-robot-suite's create-derivatives robot generated as SDR generated.
  #
  # Before sul-dlss/gis-robot-suite@ee98ad5 (2026-09-16) the robot recorded its own JP2 thumbnails with
  # sdrGeneratedText: false. The robot only discards a thumbnail marked SDR generated, and skips making a
  # new one while any thumbnail JP2 remains, so these thumbnails are never regenerated.
  #
  # Only the head version changes: earlier versions stay as they were preserved. Nothing is versioned
  # or published, since only the robot reads the flag, from the head version.
  #
  # A thumbnail is the robot's if it matches what the robot writes: an unpreserved 'use: thumbnail' JP2
  # named <source basename>.jp2, in the same file set as a preserved GIS source file. A depositor's
  # thumbnail with any other name or location is left alone (though we assume none exist).
  class MarkGisJp2ThumbnailsSdrGenerated < Base
    JP2_MIME_TYPE = 'image/jp2'
    # The source file MIME types gis-robot-suite generates thumbnails from (CreateDerivatives::MASTER_MIME_TYPES)
    SOURCE_MIME_TYPES = ['image/tiff; application=geotiff', 'application/vnd.shp', 'application/geo+json'].freeze

    def migrate
      return model_hash unless head_version? && model_hash['type'] == Cocina::Models::ObjectType.geo

      Array(model_hash.dig('structural', 'contains')).each { |file_set| mark_thumbnails(file_set) }
      model_hash
    end

    private

    def mark_thumbnails(file_set)
      files = Array(file_set.dig('structural', 'contains'))
      thumbnail_names = files.select { |file| source?(file) }.map { |file| thumbnail_name(file['filename']) }

      files.each do |file|
        file['sdrGeneratedText'] = true if robot_thumbnail?(file, thumbnail_names)
      end
    end

    def source?(file)
      file.dig('administrative', 'sdrPreserve') == true &&
        [nil, 'master'].include?(file['use']) &&
        SOURCE_MIME_TYPES.include?(file['hasMimeType'])
    end

    def robot_thumbnail?(file, thumbnail_names)
      file['hasMimeType'] == JP2_MIME_TYPE &&
        file['use'] == 'thumbnail' &&
        file['sdrGeneratedText'] != true &&
        file.dig('administrative', 'sdrPreserve') == false &&
        thumbnail_names.include?(file['filename'])
    end

    def thumbnail_name(filename)
      "#{File.basename(filename, File.extname(filename))}.jp2"
    end
  end
end
