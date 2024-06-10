# frozen_string_literal: true

module Migrators
  # Migrator that will be used to remove release tags.
  class RemoveReleaseTags < Base
    def migrate?
      repository_object.versions.any? { |version| version.administrative&.key?('releaseTags') }
    end

    def migrate
      repository_object.versions.select { |version| version.administrative&.key?('releaseTags') }.each do |version|
        next unless VersionService.can_open?(druid: repository_object.external_identifier, version: version.version)

        puts "#{repository_object.external_identifier} - Removing release tags from version #{version.version}" # rubocop:disable Rails/Output
        version.administrative.delete('releaseTags')
      end
    end
  end
end
