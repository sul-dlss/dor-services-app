# frozen_string_literal: true

module Publish
  # Merges contentMetadata from several objects into one and sends it to PURL
  class MetadataTransferService
    # @param [Cocina::Models::DRO,Cocina::Models::Collection] cocina_object the object to be publshed
    # @param [String] workflow (optional) the workflow used for reporting back status to (defaults to 'accessionWF')
    def self.publish(cocina_object, workflow: 'accessionWF')
      new(cocina_object, workflow:).publish
    end

    def initialize(cocina_object, workflow:)
      @cocina_object = cocina_object
      @workflow = workflow
      @thumbnail_service = ThumbnailService.new(cocina_object)
    end

    # Appends contentMetadata file resources from the source objects to this object
    def publish
      republish_members!
      return unpublish unless discoverable?

      public_cocina = PublicCocinaService.create(cocina_object)
      transfer_metadata(public_cocina)
      publish_notify_on_success(public_cocina)
    end

    private

    attr_reader :cocina_object, :workflow

    def transfer_metadata(public_cocina)
      public_nokogiri = PublicXmlService.new(public_cocina:,
                                             thumbnail_service: @thumbnail_service)
      transfer_to_document_store(public_cocina.to_json, 'cocina.json')
      transfer_to_document_store(public_nokogiri.to_xml, 'public')
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
      ).each do |druid|
        PublishJob.set(queue: :publish_low).perform_later(druid:, background_job_result: BackgroundJobResult.create, workflow:, log_success: false)
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
    def publish_notify_on_success(public_cocina)
      PurlFetcher::Client::LegacyPublish.publish(cocina: public_cocina)
    end

    ##
    # When deleting a PURL, we notify purl-fetcher of changes.
    #
    def publish_delete_on_success
      PurlFetcher::Client::Unpublish.unpublish(druid: cocina_object.externalIdentifier)
    end
  end
end
