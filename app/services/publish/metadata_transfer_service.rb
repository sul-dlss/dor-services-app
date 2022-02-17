# frozen_string_literal: true

module Publish
  # Merges contentMetadata from several objects into one and sends it to PURL
  class MetadataTransferService
    # @param [Dor::Item] item the object to be publshed
    def self.publish(item)
      new(item).publish
    end

    def initialize(item)
      @item = item
      @cocina_object = Cocina::Mapper.build(@item)
      @thumbnail_service = ThumbnailService.new(@cocina_object)
    end

    # Appends contentMetadata file resources from the source objects to this object
    # @raise [Dor::DataError]
    def publish
      return unpublish unless world_discoverable?

      # Retrieve release tags from identityMetadata and all collections this item is a member of
      release_tags = ReleaseTags.for(cocina_object: cocina_object)

      transfer_metadata(release_tags)
      publish_notify_on_success
    end

    private

    attr_reader :item, :cocina_object

    # @raise [Dor::DataError]
    def transfer_metadata(release_tags)
      public_cocina = PublicCocinaService.create(cocina_object)
      public_nokogiri = PublicXmlService.new(item, public_cocina: public_cocina,
                                                   released_for: release_tags,
                                                   thumbnail_service: @thumbnail_service)
      transfer_to_document_store(public_cocina.to_json, 'cocina.json')
      transfer_to_document_store(public_nokogiri.to_xml, 'public')
      transfer_to_document_store(PublicDescMetadataService.new(public_cocina).to_xml, 'mods')
    end

    # Clear out the document cache for this item
    def unpublish
      PruneService.new(druid: purl_druid).prune!
      publish_delete_on_success
    end

    def world_discoverable?
      rights = item.rightsMetadata.ng_xml.clone.remove_namespaces!
      rights.at_xpath("//rightsMetadata/access[@type='discover']/machine/world")
    end

    # Create a file inside the content directory under the stacks.local_document_cache_root
    # @param [String] content The contents of the file to be created
    # @param [String] filename The name of the file to be created
    # @return [void]
    def transfer_to_document_store(content, filename)
      new_file = File.join(purl_druid.content_dir, filename)
      Rails.logger.debug("[Publish][#{item.pid}] Writing #{new_file}")
      File.write(new_file, content)
    end

    def purl_druid
      @purl_druid ||= DruidTools::PurlDruid.new item.pid, Settings.stacks.local_document_cache_root
    end

    ##
    # When publishing a PURL, we notify purl-fetcher of changes.
    #
    def publish_notify_on_success
      Faraday.post(purl_services_url)
    end

    ##
    # When deleting a PURL, we notify purl-fetcher of changes.
    #
    def publish_delete_on_success
      Faraday.delete(purl_services_url)
    end

    def purl_services_url
      id = item.pid.gsub(/^druid:/, '')

      raise 'You have not configured perl-fetcher (Settings.purl_services_url).' unless Settings.purl_services_url

      "#{Settings.purl_services_url}/purls/#{id}"
    end
  end
end
