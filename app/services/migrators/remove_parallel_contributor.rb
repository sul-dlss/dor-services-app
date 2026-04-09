# frozen_string_literal: true

module Migrators
  # Removes the unused parallelContributor property from description in all objects and versions.
  # See parent class and Migrators::MigrationRunner for more information.
  class RemoveParallelContributor < Base
    def migrate # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # Nothing to do if there is no description
      return model_hash if model_hash['description'].nil?

      # Remove parallelContributor from all contributors
      # including any in event, parallelEvent, relatedResource, and adminMetadata
      remove_parallel_contributor(model_hash['description'])
      Array(model_hash.dig('description', 'event')).each do |event_hash|
        remove_parallel_contributor(event_hash)
        Array(event_hash['parallelEvent']).each do |parallel_event_hash|
          remove_parallel_contributor(parallel_event_hash)
        end
      end
      Array(model_hash.dig('description', 'relatedResource')).each do |related_resource_hash|
        remove_parallel_contributor(related_resource_hash)
      end
      remove_parallel_contributor(model_hash.dig('description', 'adminMetadata'))
      Array(model_hash.dig('description', 'adminMetadata', 'event')).each do |event_hash|
        remove_parallel_contributor(event_hash)
        Array(event_hash['parallelEvent']).each do |parallel_event_hash|
          remove_parallel_contributor(parallel_event_hash)
        end
      end
      model_hash
    end

    private

    def remove_parallel_contributor(resource_hash)
      return if resource_hash.nil?

      Array(resource_hash['contributor']).each do |contributor_hash|
        contributor_hash.delete('parallelContributor')
      end
    end
  end
end
