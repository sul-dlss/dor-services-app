# frozen_string_literal: true

module Migrators
  # Fake migrator that can be used to check that objects can be updated.
  class CheckCocinaUpdate < Base
    def migrate
      # This changes every object.
      model_hash['description']['title'].first['value'] = 'Test'
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
