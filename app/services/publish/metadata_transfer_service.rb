# frozen_string_literal: true

module Publish
  # Merges contentMetadata from several objects into one and sends it to PURL
  class MetadataTransferService
    # @param [Cocina::Models::DRO,Cocina::Models::Collection] cocina_object the object to be publshed
    def self.publish(cocina_object)
      new(cocina_object).publish
    end

    def initialize(cocina_object)
      @cocina_object = cocina_object
      @thumbnail_service = ThumbnailService.new(cocina_object)
    end

    # Appends contentMetadata file resources from the source objects to this object
    def publish
      republish_members!
      return unpublish unless discoverable?

      # Retrieve release tags from identityMetadata and all collections this item is a member of
      release_tags = ReleaseTags.for(cocina_object:)

      transfer_metadata(release_tags)
      publish_notify_on_success
    end

    private

    attr_reader :cocina_object

    def transfer_metadata(release_tags)
      public_cocina = PublicCocinaService.create(cocina_object)
      public_nokogiri = PublicXmlService.new(public_cocina:,
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

    def discoverable?
      cocina_object.access.view != 'dark'
    end

    def republish_members!
      return unless cocina_object&.collection?

      Array.wrap(
        MemberService.for(cocina_object.externalIdentifier, exclude_opened: true, only_published: true)
      ).each do |member|
        self.class.publish(CocinaObjectStore.find(member['id']))
      end
    end

    # Create a file inside the content directory under the stacks.local_document_cache_root
    # @param [String] content The contents of the file to be created
    # @param [String] filename The name of the file to be created
    # @return [void]
    def transfer_to_document_store(content, filename)
      new_file = File.join(purl_druid.content_dir, filename)
      Rails.logger.debug("[Publish][#{cocina_object.externalIdentifier}] Writing #{new_file}")
      File.write(new_file, content)
    end

    def purl_druid
      @purl_druid ||= DruidTools::PurlDruid.new cocina_object.externalIdentifier, Settings.stacks.local_document_cache_root
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
      raise 'You have not configured purl-fetcher (Settings.purl_services_url).' unless Settings.purl_services_url

      "#{Settings.purl_services_url}/purls/#{cocina_object.externalIdentifier.delete_prefix('druid:')}"
    end
  end
end
