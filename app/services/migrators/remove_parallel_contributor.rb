# frozen_string_literal: true

module Migrators
  # Removes the unused parallelContributor property from description in all objects and versions.
  # See parent class and Migrators::MigrationRunner for more information.
  class RemoveParallelContributor < Base
    def migrate?
      # migrate all druids since parallelContributor is stored in all objects' descriptions
      true
    end

    def migrate
      repository_object.versions.each do |version|
        migrate_version(version)
      end
    end

    def migrate_version(version) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      # Nothing to do if there is no description
      return unless version.description

      # Remove parallelContributor from all contributors
      # contributor
      remove_parallel_contributor(version.description)

      version.description['event']&.each do |event|
        # event > contributor
        remove_parallel_contributor(event)
        # event > parallelEvent > contributor
        event['parallelEvent']&.each do |parallel_event|
          remove_parallel_contributor(parallel_event)
        end
      end
      version.description['relatedResource']&.each do |related_resource|
        # relatedResource > contributor
        remove_parallel_contributor(related_resource)
        # relatedResource > event > contributor
        related_resource['event']&.each do |event|
          remove_parallel_contributor(event)
          # relatedResource > event > parallelEvent > contributor
          event['parallelEvent']&.each do |parallel_event|
            remove_parallel_contributor(parallel_event)
          end
        end
        # relatedResource > adminMetadata > contributor
        remove_parallel_contributor(related_resource&.dig('adminMetadata'))
        # relatedResource > adminMetadata > event > contributor
        related_resource&.dig('adminMetadata', 'event')&.each do |event|
          remove_parallel_contributor(event)
          # adminMetadata > event > parallelEvent > contributor
          event['parallelEvent']&.each do |parallel_event|
            remove_parallel_contributor(parallel_event)
          end
        end
      end
      # adminMetadata > contributor
      remove_parallel_contributor(version.description&.dig('adminMetadata'))
      # adminMetadata > event
      version.description&.dig('adminMetadata', 'event')&.each do |event|
        remove_parallel_contributor(event)
        # adminMetadata > event > parallelEvent > contributor
        event['parallelEvent']&.each do |parallel_event|
          remove_parallel_contributor(parallel_event)
        end
      end
    end

    private

    def remove_parallel_contributor(resource)
      resource&.dig('contributor')&.each do |contributor|
        contributor.delete('parallelContributor')
      end
    end
  end
end
