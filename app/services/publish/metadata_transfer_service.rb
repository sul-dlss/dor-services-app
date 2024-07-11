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
    end

    # Appends contentMetadata file resources from the source objects to this object
    def publish
      republish_collection_members!
      return unpublish unless discoverable?

      if Settings.enabled_features.publish_shelve
        publish_shelve
        republish_virtual_object_constituents!
      else
        transfer_metadata
        publish_notify_on_success
      end
      release_tags_on_success
    end

    private

    attr_reader :cocina_object, :workflow

    def public_cocina
      @public_cocina ||= PublicCocinaService.create(cocina_object)
    end

    def druid
      cocina_object.externalIdentifier
    end

    def transfer_metadata
      transfer_to_document_store(public_cocina.to_json, 'cocina.json')
    end

    # Clear out the document cache for this item
    def unpublish
      PruneService.new(druid: purl_druid).prune!
      publish_delete_on_success
    end

    def discoverable?
      cocina_object.access.view != 'dark'
    end

    def republish_collection_members!
      return unless cocina_object&.collection?

      Array.wrap(
        MemberService.for(cocina_object.externalIdentifier, exclude_opened: true, only_published: true)
      ).each do |druid|
        PublishJob.set(queue: :publish_low).perform_later(druid:, background_job_result: BackgroundJobResult.create, workflow:, log_success: false)
      end
    end

    def republish_virtual_object_constituents!
      VirtualObjectService.constituents(cocina_object, exclude_opened: true, only_published: true).each do |druid|
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
    def publish_notify_on_success
      PurlFetcher::Client::LegacyPublish.publish(cocina: public_cocina)
    end

    def release_tags_on_success
      tags = ReleaseTagService.for_public_metadata(cocina_object: public_cocina)
      actions = { index: [], delete: [] }.tap do |releases|
        tags.each do |tag|
          releases[tag.release ? :index : :delete] << tag.to
        end
      end
      # It is important to make this call even if there are no release tags for this object, because purl-fetcher will automatically add:
      # SearchWorksPreview and ContentSearch
      PurlFetcher::Client::ReleaseTags.release(druid:, **actions)
    end

    ##
    # When deleting a PURL, we notify purl-fetcher of changes.
    #
    def publish_delete_on_success
      PurlFetcher::Client::Unpublish.unpublish(druid:)
    rescue PurlFetcher::Client::AlreadyDeletedResponseError
      # It's fine. The object is already deleted.
    end

    def publish_shelve
      ShelvableFilesStager.stage(druid:, version: cocina_object.version, filepaths: filepaths_to_shelve, workspace_content_pathname:) if filepaths_to_shelve.present?
      filepath_map.each do |filename, stage_filename|
        copy(workspace_content_pathname.join(filename), transfer_stage_pathname.join(stage_filename))
      end
      PurlFetcher::Client::Publish.publish(cocina: public_cocina, file_uploads: filepath_map)
    end

    def workspace_content_pathname
      @workspace_content_pathname ||= begin
        # determine the location of the object's content files in the workspace area
        workspace_druid = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
        # In stage, we consistently get Errno::EEXIST.
        # The theory is that this is a sync issue with the underlying filesystem.
        # This addresses the issue by retrying the operation; upon retry, the directory should be found
        # to exist and the operation should succeed properly.
        begin
          Pathname(workspace_druid.content_dir(true))
        rescue Errno::EEXIST
          retry
        end
      end
    end

    def copy(src_pathname, dest_pathname)
      return if dest_pathname.exist?

      Rails.logger.info("Copying #{src_pathname} (#{src_pathname.size} bytes) to #{dest_pathname} for #{druid}")
      FileUtils.copy(src_pathname, dest_pathname)

      raise "Copy #{src_pathname} to #{dest_pathname} failed" unless dest_pathname.exist? && dest_pathname.size == src_pathname.size
    end

    def transfer_stage_pathname
      @transfer_stage_pathname ||= Pathname(Settings.stacks.transfer_stage_root)
    end

    def filepaths_to_shelve
      @filepaths_to_shelve ||= public_cocina.dro? ? DigitalStacksDiffer.call(cocina_object: public_cocina) : []
    end

    def filepath_map
      @filepath_map ||= filepaths_to_shelve.index_with do |_filename|
        SecureRandom.uuid
      end
    end
  end
end
