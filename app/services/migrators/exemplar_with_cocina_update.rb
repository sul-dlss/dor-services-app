# frozen_string_literal: true

module Migrators
  # Very basic migrator that will be used to test the cocina migration runner and illustrate usage.
  # See parent class and Migrators::MigrationRunner for more information.
  class ExemplarWithCocinaUpdate < Exemplar
    def self.migration_strategy
      :cocina_update
    end

    def self.version_description
      'Testing migration'
    end
  end
end
