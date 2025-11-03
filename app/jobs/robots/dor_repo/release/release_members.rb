# frozen_string_literal: true

module Robots
  module DorRepo
    module Release
      # Release the member of a collection
      class ReleaseMembers < Robots::Robot
        def initialize
          super('releaseWF', 'release-members')
        end

        def perform_work
          return unless cocina_object.collection?
          return unless add_wf_to_members?

          published_members.each do |member|
            create_release_workflow(druid: member.external_identifier, version: member.version)
          end
        end

        private

        def published_members
          # .currently_members_of_collection returns a sparse RepositoryObject.
          RepositoryObject.currently_members_of_collection(druid).select do |member|
            published?(druid: member.external_identifier)
          end
        end

        def published?(druid:)
          # This is for the member, not the parent collection.
          Workflow::LifecycleService.milestone?(druid:, milestone_name: 'published')
        end

        # Here's an example of the kinds of tags we're dealing with:
        #   https://argo.stanford.edu/view/druid:fh138mm2023
        # @return [boolean] returns true if the most recent releaseTags for any target is "collection"
        def add_wf_to_members?
          ReleaseTagService.tags(druid:)
                           .group_by(&:to)
                           .transform_values { |v| v.max_by(&:date) }
                           .values.map(&:what).any?('collection')
        end

        def create_release_workflow(druid:, version:)
          # This is for the member, not the parent collection.
          Workflow::Service.create(druid:, version:, workflow_name: 'releaseWF', lane_id:)
        end
      end
    end
  end
end
