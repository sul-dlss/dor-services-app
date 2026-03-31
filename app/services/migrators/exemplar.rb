# frozen_string_literal: true

module Migrators
  # Very basic migrator that will be used to test the cocina migration runner and illustrate usage.
  # See parent class and Migrators::MigrationRunner for more information.
  class Exemplar < Base
    # NOTE: these are QA druids from 2026-03-30
    TEST_DRUIDS = [
      'druid:bb029tv6105',
      'druid:bb086gc7372'
    ].freeze

    def self.druids
      TEST_DRUIDS
    end

    def migrate?
      TEST_DRUIDS.include?(repository_object.external_identifier)
    end

    def migrate
      head_rov.label = mark_migrated(head_rov.label)
      head_rov.description['title'].first['value'] = mark_migrated(head_rov.description['title'].first['value'])
    end

    def updated_head_version_cocina_object
      head_rov.to_cocina_with_metadata # This validates the cocina object
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
