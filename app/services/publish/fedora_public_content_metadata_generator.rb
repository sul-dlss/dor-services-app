# frozen_string_literal: true

module Publish
  # Exports the contentMetadata XML that is a part of the public xml displayed on purl.stanford.edu
  class FedoraPublicContentMetadataGenerator
    # @param [Dor::Item] fedora_object
    # @return [Nokogiri::XML::Document] sanitized for public consumption
    def self.generate(fedora_object:)
      new(fedora_object).generate
    end

    attr_reader :fedora_object

    # @param [Dor::Item] fedora_object
    def initialize(fedora_object)
      @fedora_object = fedora_object
    end

    # @return [Nokogiri::XML::Document] sanitized for public consumption
    def generate
      return Nokogiri::XML::Document.new unless fedora_object.datastreams['contentMetadata']

      result = fedora_object.datastreams['contentMetadata'].ng_xml.clone

      result.xpath('/contentMetadata/resource').each do |resource|
        # PURL uses these resource identifiers to generate IIIF Manifests.
        # Each of these identifiers represents a IIIF Canvas and would look like:
        #   https://purl.stanford.edu/vq627fg9932/iiif/canvas/cocina-fileSet-UUID
        # We're removing the protocol://host/path/ part of this so these Canvas URIs don't have a URI embeded in a URI.
        resource['id'] = resource['id'].sub('http://cocina.sul.stanford.edu/fileSet/', 'cocina-fileSet-')
      end

      # remove any resources or attributes that are not destined for the public XML
      result.xpath('/contentMetadata/resource[not(file[(@deliver="yes" or @publish="yes")]|externalFile)]').each(&:remove)
      result.xpath('/contentMetadata/resource/file[not(@deliver="yes" or @publish="yes")]').each(&:remove)
      result.xpath('/contentMetadata/resource/file').xpath('@preserve|@shelve|@publish|@deliver').each(&:remove)
      result.xpath('/contentMetadata/resource/file/checksum').each(&:remove)

      # support for dereferencing links via externalFile element(s) to the source (child) item - see JUMBO-19
      result.xpath('/contentMetadata/resource/externalFile').each do |external_file|
        add_data_from_src(external_file)
      end

      result
    end

    def add_data_from_src(external_file)
      # enforce pre-conditions that resourceId, objectId, fileId are required
      src_resource_id = external_file['resourceId']
      src_druid = external_file['objectId']
      src_file_id = external_file['fileId']
      raise Dor::DataError, "Malformed externalFile data: #{external_file.to_xml}" if [src_resource_id, src_file_id, src_druid].map(&:blank?).any?

      # grab source item
      src_item = Dor.find(src_druid)

      # locate and extract the resourceId/fileId elements
      doc = src_item.contentMetadata.ng_xml
      src_resource = doc.at_xpath("//resource[@id=\"#{src_resource_id}\"]")

      unless src_resource
        raise Dor::DataError, "The contentMetadata of #{fedora_object.pid} has an externalFile "\
                              "reference to #{src_druid}, #{src_resource_id}, but #{src_druid} doesn't have " \
                              'a matching resource node in its contentMetadata'
      end

      src_file = src_resource.at_xpath("file[@id=\"#{src_file_id}\"]")
      raise Dor::DataError, "Unable to find a file node with id=\"#{src_file_id}\" (child of #{fedora_object.pid})" unless src_file

      src_image_data = src_file.at_xpath('imageData')

      # always use title regardless of whether a child label is present
      src_label = doc.create_element('label')
      src_label.content = src_item.full_title

      # PURL uses these resource identifiers to generate IIIF Manifests.
      # Each of these identifiers represents a IIIF Canvas and would look like:
      #   https://purl.stanford.edu/vq627fg9932/iiif/canvas/cocina-fileSet-UUID
      external_file['resourceId'] = external_file['resourceId'].sub('http://cocina.sul.stanford.edu/fileSet/', 'cocina-fileSet-')

      # add the extracted label and imageData
      external_file.add_previous_sibling(src_label)
      external_file << src_image_data unless src_image_data.nil?
    end
  end
end
