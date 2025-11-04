# frozen_string_literal: true

module Publish
  # Encapsulates an item to be published.

  # Note that if a user_version is specified, that user version will be used.
  # If a user_version is not specified and the object has user versions, the latest user version will be used.
  # If the object does not have user versions, the latest closed version will be used as user version 1.
  class Item
    def initialize(druid:, user_version: nil)
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
      !Cocina::Support.dark?(cocina_object)
    end

    def must_version?
      user_version.present?
    end

    # @return [Boolean] whether the item has been published for the published version
    def published?
      return false if repository_object_version.nil?

      Workflow::LifecycleService.milestone?(druid:, milestone_name: 'published', version: version)
    end

    delegate :version, to: :repository_object_version

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
