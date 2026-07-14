# frozen_string_literal: true

module Migrators
  # Fake migrator that can be used to check that objects can be updated.
  class CheckCocinaUpdate < Base
    def migrate
      # This changes every object by adding a title to the description,
      # and creating a description first if it doesn't exist.
      description = model_hash['description'] || {}
      titles = description['title'] || []

      titles << { 'value' => 'Test' }
      description['title'] = titles
      model_hash['description'] = description

      model_hash
    end

    def self.migration_strategy
      :cocina_update
    end

    def self.version_description
      'Testing migration'
    end

    # Guarantee that this migrator will not be run in non-dryrun mode since it changes every object.
    def self.dryrun_only?
      true
    end
  end
end
