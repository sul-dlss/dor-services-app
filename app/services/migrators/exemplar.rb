# frozen_string_literal: true

module Migrators
  # Migrator that will be used to test the migration.
  # See Migrators::Base for more information.
  class Exemplar < Base
    # NOTE: these are QA druids from 2023-02-23
    TEST_DRUIDS = [
      'druid:bc177tq6734',
      'druid:rd069rk9728'
    ].freeze

    # A migrator may provide a list of druids to be migrated (optional).
    def self.druids
      TEST_DRUIDS
    end

    # A migrator must implement a migrate? method that returns true if the SDR object should be migrated.
    def migrate?
      TEST_DRUIDS.include?(repository_object.external_identifier)
    end

    # A migrator must implement a migrate method that migrates (mutates) the RepositoryObject instance.
    def migrate # rubocop:disable Metrics/AbcSize
      repository_object.head_version.label = mark_migrated(repository_object.head_version.label)
      repository_object.head_version.description['title'].first['value'] =
        mark_migrated(repository_object.head_version.description['title'].first['value'])
    end

    private

    def mark_migrated(label)
      "#{label.gsub(/ - migrated .+$/, '')} - migrated #{Time.now.utc.iso8601}"
    end
  end
end
