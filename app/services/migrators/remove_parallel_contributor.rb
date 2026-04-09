# frozen_string_literal: true

module Migrators
  # Removes the unused parallelContributor property from description in all objects and versions.
  # See parent class and Migrators::MigrationRunner for more information.
  class RemoveParallelContributor < Base
    def migrate
      remove_parallel_contributor_from_resource(model_hash['description'])

      model_hash
    end

    private

    def remove_parallel_contributor_from_resource(resource_hash) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return if resource_hash.nil?

      # Remove from contributor
      remove_parallel_contributor(resource_hash)
      Array(resource_hash['event']).each do |event_hash|
        # Remove from event > contributor
        remove_parallel_contributor(event_hash)
        # Remove from event > parallelEvent > contributor
        Array(event_hash['parallelEvent']).each do |parallel_event_hash|
          remove_parallel_contributor(parallel_event_hash)
        end
      end
      # Remove from relatedResource > contributor
      Array(resource_hash['relatedResource']).each do |related_resource_hash|
        remove_parallel_contributor_from_resource(related_resource_hash)
      end

      # Remove from adminMetadata > contributor
      remove_parallel_contributor(resource_hash['adminMetadata'])
      Array(resource_hash.dig('adminMetadata', 'event')).each do |event_hash|
        # Remove from adminMetadata > event > contributor
        remove_parallel_contributor(event_hash)
        # Remove from adminMetadata > event > parallelEvent > contributor
        Array(event_hash['parallelEvent']).each do |parallel_event_hash|
          remove_parallel_contributor(parallel_event_hash)
        end
      end
    end

    def remove_parallel_contributor(hash)
      return if hash.nil?

      Array(hash['contributor']).each do |contributor_hash|
        contributor_hash.delete('parallelContributor')
      end
    end
  end
end
