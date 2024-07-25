# frozen_string_literal: true

module Publish
  # Updates access system with the content and metadata of the object, i.e., publishing and shelving.
  # Note that if a user_version is specified, that user version will be published.
  # If a user_version is not specified and the object has user versions, the latest user version will be published.
  # If the object does not have user versions, the latest closed version will be published as version 1.
  class MetadataTransferService
    # @param [String] druid for the object to be published
    # @param [String] user_version if a specific version is to be published
    # @param [String] workflow (optional) the workflow used for reporting back status to (defaults to 'accessionWF')
    def self.publish(druid:, user_version: nil, workflow: 'accessionWF')
      new(druid:, workflow:, user_version:).publish
    end

    def initialize(druid:, workflow:, user_version:)
      @workflow = workflow
      @public_cocina = PublicCocina.new(druid:, user_version:)
    end

    # Updates access system with the content and metadata of the object
    def publish
      republish_collection_members! if cocina_object.collection?
      return publish_delete_on_success unless discoverable?

      publish_shelve
      check_stacks if public_cocina.dro?
      republish_virtual_object_constituents!
      release_tags_on_success
    end

    private

    attr_reader :workflow

    delegate :cocina_object, :druid, :public_cocina, :public_version, :user_version, :discoverable?, :version_date, :must_version?, to: :@public_cocina

    def republish_collection_members!
      Array.wrap(
        MemberService.for(druid, exclude_opened: true, only_published: true)
      ).each do |member_druid|
        PublishJob.set(queue: :publish_low).perform_later(druid: member_druid, background_job_result: BackgroundJobResult.create, workflow:, log_success: false)
      end
    end

    def republish_virtual_object_constituents!
      VirtualObjectService.constituents(cocina_object, exclude_opened: true, only_published: true).each do |constituent_druid|
        PublishJob.set(queue: :publish_low).perform_later(druid: constituent_druid, background_job_result: BackgroundJobResult.create, workflow:, log_success: false)
      end
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
      PurlFetcher::Client::Unpublish.unpublish(druid:, version: public_version)
    rescue PurlFetcher::Client::AlreadyDeletedResponseError
      # It's fine. The object is already deleted.
    end

    def publish_shelve
      if filepaths_to_shelve.present?
        ShelvableFilesStager.stage(cocina_object:, filepaths: filepaths_to_shelve, workspace_content_pathname:)
        TransferStager.copy(druid:, filepath_map: filepath_uuid_map, workspace_content_pathname:)
      end
      PurlFetcher::Client::Publish.publish(cocina: public_cocina, file_uploads: filepath_uuid_map, version: public_version,
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

    # Encapsulates cocina to be published.
    class PublicCocina
      def initialize(druid:, user_version:)
        @druid = druid
        @user_version = user_version || UserVersionService.latest_user_version(druid:)
      end

      # @return [Cocina::Models::DRO, Cocina::Models::Collection] the cocina object to publish
      def cocina_object
        repository_object_version.to_cocina_with_metadata
      end

      def public_cocina
        @public_cocina ||= PublicCocinaService.create(cocina_object)
      end

      def public_version
        @public_version ||= user_version || 1
      end

      def version_date
        repository_object_version.closed_at
      end

      def discoverable?
        cocina_object.access.view != 'dark'
      end

      def must_version?
        user_version.present?
      end

      attr_reader :druid, :user_version

      private

      def repository_object
        @repository_object ||= RepositoryObject.find_by!(external_identifier: druid)
      end

      def repository_object_version
        @repository_object_version ||= if user_version
                                         object_version = UserVersionService.object_version_for(druid:, user_version:)
                                         repository_object.versions.find_by!(version: object_version)
                                       else
                                         repository_object.last_closed_version
                                       end
      end
    end
  end
end
