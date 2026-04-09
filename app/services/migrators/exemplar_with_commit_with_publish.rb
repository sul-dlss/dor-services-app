# frozen_string_literal: true

module Migrators
  # Very basic migrator that will be used to test the cocina migration runner and illustrate usage.
  # See parent class and Migrators::MigrationRunner for more information.
  class ExemplarWithCommitWithPublish < Exemplar
    def self.migration_strategy
      :commit_with_publish
    end
  end
end
