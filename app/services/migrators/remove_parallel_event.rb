# frozen_string_literal: true

module Migrators
  # Removes the unused parallelEvent property from description in all objects and versions.
  # See parent class and Migrators::MigrationRunner for more information.
  class RemoveParallelEvent < Base
    def migrate
      remove_parallel_event_from_resource(model_hash['description'])

      model_hash
    end

    private

    def remove_parallel_event_from_resource(resource_hash)
      return if resource_hash.nil?

      remove_parallel_event(resource_hash)

      Array(resource_hash['relatedResource']).each do |related_resource_hash|
        remove_parallel_event_from_resource(related_resource_hash)
      end

      remove_parallel_event(resource_hash['adminMetadata'])
    end

    def remove_parallel_event(hash)
      return if hash.nil?

      Array(hash['event']).each do |event_hash|
        event_hash.delete('parallelEvent') if delete?(event_hash)
      end

      Array(hash['event']).delete_if do |event_hash|
        %w[date contributor location identifier note structuredValue parallelEvent].none? do |field|
          event_hash[field].present?
        end
      end
    end

    def delete?(event_hash)
      return false unless event_hash.key?('parallelEvent')

      event_hash['parallelEvent'].empty? || opened_version? || last_closed_version?
    end
  end
end
