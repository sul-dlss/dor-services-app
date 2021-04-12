# frozen_string_literal: true

module Publish
  # Exports the full object XML that we display on purl.stanford.edu
  class PublicXmlService
    attr_reader :object

    # @param [Dor::Item] object
    # @param [Hash{String => Boolean}] released_for keys are Project name strings, values are boolean
    def initialize(object, released_for:)
      @object = object
      @released_for = released_for
    end

    # @raise [Dor::DataError]
    # rubocop:disable Metrics/AbcSize
    def to_xml
      pub = Nokogiri::XML('<publicObject/>').root
      pub['id'] = object.pid
      pub['published'] = Time.now.utc.xmlschema
      pub['publishVersion'] = 'dor-services/' + Dor::VERSION

      pub.add_child(public_identity_metadata.root) # add in modified identityMetadata datastream
      pub.add_child(public_content_metadata.root) if public_content_metadata.xpath('//resource').any?
      pub.add_child(public_rights_metadata.root)
      pub.add_child(public_relationships.root)
      pub.add_child(DublinCoreService.new(object).ng_xml.root)
      pub.add_child(PublicDescMetadataService.new(object).ng_xml.root)
      pub.add_child(release_xml.root) unless release_xml.xpath('//release').children.empty? # If there are no release_tags, this prevents an empty <releaseData/> from being added
      # Note we cannot base this on if an individual object has release tags or not, because the collection may cause one to be generated for an item,
      # so we need to calculate it and then look at the final result.

      thumb = ThumbnailService.new(object).thumb
      pub.add_child(Nokogiri("<thumb>#{thumb}</thumb>").root) unless thumb.nil?

      new_pub = Nokogiri::XML(pub.to_xml, &:noblanks)
      new_pub.encoding = 'UTF-8'
      new_pub.to_xml
    end
    # rubocop:enable Metrics/AbcSize

    private

    attr_reader :released_for

    # Generate XML structure for inclusion to Purl
    # @return [String] The XML release node as a string, with ReleaseDigest as the root document
    def release_xml
      @release_xml ||= begin
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.releaseData do
            released_for.each do |project, released_value|
              xml.release(released_value['release'], to: project)
            end
          end
        end
        Nokogiri::XML(builder.to_xml)
      end
    end

    def public_relationships
      PublishedRelationshipsFilter.new(object).xml
    end

    def public_rights_metadata
      @public_rights_metadata ||= RightsMetadata.new(object.rightsMetadata.ng_xml).create
    end

    def public_identity_metadata
      @public_identity_metadata ||= begin
        im = object.datastreams['identityMetadata'].ng_xml.clone
        im.search('//release').each(&:remove) # remove any <release> tags from public xml which have full history
        im
      end
    end

    # @return [Nokogiri::XML::Document] sanitized for public consumption
    def public_content_metadata
      return Nokogiri::XML::Document.new unless object.datastreams['contentMetadata']

      @public_content_metadata ||= begin
        result = object.datastreams['contentMetadata'].ng_xml.clone

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
        raise Dor::DataError, "The contentMetadata of #{object.pid} has an externalFile "\
          "reference to #{src_druid}, #{src_resource_id}, but #{src_druid} doesn't have " \
          'a matching resource node in its contentMetadata'
      end

      src_file = src_resource.at_xpath("file[@id=\"#{src_file_id}\"]")
      raise Dor::DataError, "Unable to find a file node with id=\"#{src_file_id}\" (child of #{object.pid})" unless src_file

      src_image_data = src_file.at_xpath('imageData')

      # always use title regardless of whether a child label is present
      src_label = doc.create_element('label')
      src_label.content = src_item.full_title

      # add the extracted label and imageData
      external_file.add_previous_sibling(src_label)
      external_file << src_image_data unless src_image_data.nil?
    end
  end
end
