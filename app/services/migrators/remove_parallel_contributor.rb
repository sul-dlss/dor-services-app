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

    # rubocop:disable Metrics/CyclomaticComplexity
    def migrate_version(version)
      # Nothing to do if there is no description
      return unless version.description

      # Remove parallelContributor from all contributors, events contributors, and relatedResource contributors.
      remove_parallel_contributor(version.description)
      version.description['event']&.each do |event|
        remove_parallel_contributor(event)
      end
      version.description['relatedResource']&.each do |related_resource|
        remove_parallel_contributor(related_resource)
        related_resource['relatedResource']&.each do |nested_related_resource|
          remove_parallel_contributor(nested_related_resource)
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    private

    def remove_parallel_contributor(resource)
      resource&.dig('contributor')&.each do |contributor|
        contributor.delete('parallelContributor')
      end
    end
  end
end
