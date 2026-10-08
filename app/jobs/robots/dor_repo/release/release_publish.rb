# frozen_string_literal: true

module Robots
  module DorRepo
    module Release
      # Sends release tags to Purl Fetcher
      class ReleasePublish < Robots::Robot
        class PublishNotCompleteError < StandardError; end

        def initialize
          super('releaseWF', 'release-publish', retriable_exceptions: [Robots::DorRepo::Release::ReleasePublish::PublishNotCompleteError])
        end

        def perform_work
          if dark?
            return LyberCore::ReturnState.new(status: :skipped,
                                              note: 'item is dark so it cannot be published')
          end

          # Ensure that item has been published before releasing.
          raise PublishNotCompleteError unless published_version_available?

          PurlFetcher::Client::ReleaseTags.release(
            druid:,
            index: targets_for(release: true),
            delete: targets_for(release: false)
          )
        end

        def release_tags
          @release_tags ||= PublicMetadataReleaseTagService.for_public_metadata(cocina_object:)
        end

        def targets_for(release:)
          release_tags.select { |tag| tag.release == release }.map(&:to)
        end

        def dark?
          Cocina::Support.dark?(cocina_object)
        end

        def published_version_available?
          workflow_version = version.to_i

          # The release workflow version itself has been published.
          return true if version_published?(version: workflow_version)

          # The release workflow may have started for a newer open version while an earlier version
          # was already published. See https://github.com/sul-dlss/dor-services-app/issues/6278.
          latest_version = latest_published_version
          latest_version.present? && latest_version < workflow_version
        end

        def version_published?(version:)
          Workflow::LifecycleService.milestone?(druid:, milestone_name: 'published', version:)
        end

        def latest_published_version
          Workflow::LifecycleService.latest_milestone_version(druid:, milestone_name: 'published')
        end
      end
    end
  end
end
