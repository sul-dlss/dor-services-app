# frozen_string_literal: true

module Migrators
  # Very basic migrator that will be used to test the migration.
  # See parent class and Migrators::MigrationRunner for more information.
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
    def migrate
      head_rov.label = mark_migrated(head_rov.label)
      head_rov.description['title'].first['value'] = mark_migrated(head_rov.description['title'].first['value'])
    end

    private

    def mark_migrated(label)
      "#{label.gsub(/ - migrated .+$/, '')} - migrated #{Time.now.utc.iso8601}"
    end

    def head_rov
      # NOTE: a Ruby Enumerable#find on the versions association is used so that the autosave behavior works
      # on the modified version. Looping over the association with e.g. #each would also work. But e.g. an ActiveRecord
      # #find (by PK ID) or #where on the association would return a new relation, and objects returned by that relation
      # would _not_ be autosaved when the parent repository_object (passed to this migrator instance) is saved.
      @head_rov ||= repository_object.versions.find { |rov| rov.id == repository_object.head_version_id }
    end
  end
end
