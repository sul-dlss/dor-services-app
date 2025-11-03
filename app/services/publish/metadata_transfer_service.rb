# frozen_string_literal: true

module Publish
  # Updates access system with the content and metadata of the object, i.e., publishing and shelving.
  # Note that if a user_version is specified, that user version will be published.
  # If a user_version is not specified and the object has user versions, the latest user version will be published.
  # If the object does not have user versions, the latest closed version will be published as version 1.
  class MetadataTransferService
    # @param [String] druid for the object to be published
    # @param [Integer] user_version if a specific version is to be published
    def self.publish(druid:, user_version: nil)
      new(druid:, user_version:).publish
    end

    def initialize(druid:, user_version:)
      @publish_item = Publish::Item.new(druid:, user_version:)
    end

    # Updates access system with the content and metadata of the object
    def publish
      republish_collection_members! if cocina_object.collection?
      return publish_delete_on_success unless discoverable?

      publish_shelve
      check_stacks if public_cocina.dro?
      republish_virtual_object_constituents!
    end

    private

    attr_reader :workflow

    delegate :cocina_object, :druid, :public_cocina, :public_version, :user_version, :discoverable?, :version_date,
             :must_version?, to: :@publish_item

    def republish_collection_members!
      Array.wrap(
        MemberService.for(druid, publishable: true)
      ).each do |member_druid|
        PublishJob.set(queue: :publish_low).perform_later(druid: member_druid,
                                                          background_job_result: BackgroundJobResult.create)
      end
    end

    def republish_virtual_object_constituents!
      VirtualObjectService.constituents(cocina_object, publishable: true).each do |constituent_druid|
        PublishJob.set(queue: :publish_low).perform_later(druid: constituent_druid,
                                                          background_job_result: BackgroundJobResult.create)
      end
    end

    ##
    # When deleting a PURL, we notify purl-fetcher of changes.
    #
    def publish_delete_on_success
      PurlFetcher::Client::Unpublish.unpublish(druid:, version: public_version)
    rescue PurlFetcher::Client::AlreadyDeletedResponseError
      # It's fine. The object is already deleted.
    end

    def publish_shelve
      if filepaths_to_shelve.present?
        ShelvableFilesStager.stage(cocina_object:, filepaths: filepaths_to_shelve, workspace_content_pathname:)
        TransferStager.copy(druid:, filepath_map: filepath_uuid_map, workspace_content_pathname:)
      end
      PurlFetcher::Client::Publish.publish(cocina: public_cocina, file_uploads: filepath_uuid_map,
                                           version: public_version,
                                           must_version: must_version?, version_date:)
    end

    def check_stacks
      missing_filepaths = DigitalStacksDiffer.call(cocina_object: public_cocina)

      raise "Files are missing from stacks: #{missing_filepaths}" if missing_filepaths.present?
    end

    def filepaths_to_shelve
      @filepaths_to_shelve ||= public_cocina.dro? ? DigitalStacksDiffer.call(cocina_object: public_cocina) : []
    end

    def filepath_uuid_map
      @filepath_uuid_map ||= filepaths_to_shelve.index_with do |_filename|
        SecureRandom.uuid
      end
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
  end
end
