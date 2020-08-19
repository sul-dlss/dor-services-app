# frozen_string_literal: true

module Publish
  # For presentation, we need to know the image dimensions
  # see https://github.com/sul-dlss/purl/blob/27b881991f2dfc53dd5f151f7f67726a2d355e93/app/models/content_metadata.rb#L125-L127
  # We retrieve this data from the technical metadata service.
  class ContentMetadataWithImageSizes
    def initialize(content_metadata)
      @content_metadata = content_metadata
    end

    def to_xml
      content_metadata.ng_xml.xpath('//contentMetadata/resource/file').each do |file|
        next unless image? file['mimetype']

        data = technical_metadata.find { |i| i['filename'] == file['id'] }
        next unless data && data['image_metadata']

        file.search('imageData').each(&:remove)
        file.add_child("  <imageData height=\"#{data.dig('image_metadata', 'height')}\" width=\"#{data.dig('image_metadata', 'height')}\" />\n")
      end
      content_metadata.to_xml
    end

    private

    attr_reader :content_metadata

    # @return [Symbol] the type of object, could be :application (for PDF or Word, etc), :audio, :image, :message, :model, :multipart, :text or :video
    def object_type(mimetype)
      lookup = MIME::Types[mimetype][0]
      lookup.nil? ? :other : lookup.media_type.to_sym
    end

    # @return [Boolean] if object is an image
    def image?(mimetype)
      object_type(mimetype) == :image
    end

    def technical_metadata
      @technical_metadata ||= TechmdService.techmd_for(druid: content_metadata.pid)
    end
  end
end
