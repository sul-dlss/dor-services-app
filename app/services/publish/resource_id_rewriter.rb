# frozen_string_literal: true

module Publish
  # Rewrite resource identifiers so they can be used as URI components by IIIF
  class ResourceIdRewriter
    # PURL uses these resource identifiers to generate IIIF Manifests.
    # Each of these identifiers represents a IIIF Canvas and would look like:
    #   https://purl.stanford.edu/vq627fg9932/iiif/canvas/cocina-fileSet-UUID
    # @param [String] xml
    # @return [Nokogiri::XML::Document] sanitized for public consumption
    def self.call(xml)
      new(xml).generate
    end

    attr_reader :result

    # @param [String] xml
    def initialize(xml)
      @result = Nokogiri::XML(xml)
    end

    # @return [Nokogiri::XML::Document] xml doc that has URI identifiers rewritten
    def generate
      result.xpath('/contentMetadata/resource').each do |resource|
        resource['id'] = resource['id'].sub('https://cocina.sul.stanford.edu/fileSet/', 'cocina-fileSet-')
      end

      result.xpath('/contentMetadata/resource/externalFile').each do |external_file|
        external_file['resourceId'] = external_file['resourceId'].sub('https://cocina.sul.stanford.edu/fileSet/', 'cocina-fileSet-')
      end

      result
    end
  end
end
