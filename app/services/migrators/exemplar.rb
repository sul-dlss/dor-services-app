# frozen_string_literal: true

module Migrators
  # Migrator that will be used to test the migration.
  # See Migrators::Base for more information.
  class Exemplar < Base
    # A migrator may provide a list of druids to be migrated (optional).
    def self.druids
      TEST_DRUIDS
    end

    # A migrator must implement a migrate? method that returns true if the SDR object should be migrated.
    def migrate?
      TEST_DRUIDS.include?(ar_cocina_object.external_identifier)
    end

    # A migrator must implement a migrate method that migrates (mutates) the ActiveRecord cocina object.
    def migrate
      ar_cocina_object.label = mark_migrated(ar_cocina_object.label)
      ar_cocina_object.description['title'].first['value'] = mark_migrated(ar_cocina_object.description['title'].first['value'])
    end

    private

    # NOTE: these are QA druids from 2023-02-23
    TEST_DRUIDS = [
      'druid:bc177tq6734',
      'druid:rd069rk9728'
    ].freeze

    def mark_migrated(label)
      "#{label.gsub(/ - migrated .+$/, '')} - migrated #{Time.now.utc.iso8601}"
    end
  end
end
