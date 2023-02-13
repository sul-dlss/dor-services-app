# frozen_string_literal: true

module Migrators
  # Migrator that will be used to test the migration.
  # See base.rb for more information.
  class Test < Base
    # A migrator may provide a list of druids to be migrated (optional).
    def self.druids
      TEST_DRUIDS
    end

    # A migrator must implement a migrate? method that returns true if the object should be migrated.
    def migrate?
      TEST_DRUIDS.include?(obj.external_identifier)
    end

    # A migrator must implement a migrate method that migrates (mutates) the object.
    def migrate
      obj.label = mark_migrated(obj.label)
      obj.description['title'].first['value'] = mark_migrated(obj.description['title'].first['value'])
    end

    private

    # These are QA druids.
    TEST_DRUIDS = [
      'druid:bc177tq6734',
      'druid:rd069rk9728'
    ].freeze

    def mark_migrated(label)
      "#{label.gsub(/ - migrated .+$/, '')} - migrated #{Time.now.utc.iso8601}"
    end
  end
end
