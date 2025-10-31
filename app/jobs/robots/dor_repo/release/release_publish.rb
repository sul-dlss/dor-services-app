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
          raise PublishNotCompleteError unless published_milestone_present?

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

        def published_milestone_present?
          # Use Publish::Item to get the version being published.
          publish_item = Publish::Item.new(druid:)
          Workflow::LifecycleService.milestone?(druid:, milestone_name: 'published', version: publish_item.version)
        end
      end
    end
  end
end
