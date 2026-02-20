# frozen_string_literal: true

module Migrators
  # Base migrator.
  # Depends on logic in Migrators::MigrationRunner (invokable as a script via bin/migrate-cocina) which may also
  # open/close versions, validate cocina, and/or save updated RepositoryObject records.
  #
  # The migrator subclass _must_ implement the following methods:
  #   migrate? - true if the object should be migrated
  #   migrate - migrates the object and returns the result
  # The migrator subclass _may_ override the following methods:
  #   version? - true if the object should be versioned
  #   publish? - true if the object should be published
  #   initialize(active_record_object)
  # For any repository_object where version? returns true, the migrator must implement:
  #   version_description - description for the version
  # See app/services/migrators/exemplar.rb for an example.
  class Base
    # Return an array of druids to be migrated, or nil if all druids should be migrated.
    def self.druids
      nil
    end

    # @param [RepositoryObject] repository_object - a RepositoryObject instance
    def initialize(repository_object)
      @repository_object = repository_object
    end

    # A migrator must implement a migrate? method that returns true if the SDR object should be migrated.
    def migrate?
      raise NotImplementedError
    end

    # A migrator must implement a migrate method that migrates (mutates) the RepositoryObject instance and/or
    # one or more of its versions (RepositoryObjectVersion).
    # @note the #migrate method SHOULD update versions that are tied to repository_object via an autosave
    # association, so that if the parent repository_object is saved by the migration runner framework (which
    # invokes this #migrate method), the updated version(s) touched by the migrator will also be saved; but the
    # #migrate method SHOULD NOT explicitly save any ActiveRecord objects, so that dry run and validation behavior
    # can be coordinated by the migration runner.
    # @see Migrators::Exemplar#head_rov
    # @todo A future enhancement could be to have the constructor take an optional mode, so that future migrator classes
    # can look at the mode flag and explicitly save as needed, to remove the current autosave requirement.
    def migrate
      raise NotImplementedError
    end

    # subclass can override if it updates the head_version via a different ActiveRecord association
    def updated_head_version_cocina_object
      repository_object.head_version.to_cocina_with_metadata # This validates the cocina object
    end

    # A migrator may override the publish? method to return true for some or all migrated SDR objects
    # When true, the migrated object will be published.
    def publish?
      false
    end

    # A migrator may override the version? method to return true for some or all migrated SDR objects
    # When true, the migrated object will be versioned (and thus trigger common_accessioning)
    def version?
      false
    end

    # if version? is ever true, then version_description must be implemented
    # A migrator may override the version_description method to provide a version description for
    # versionined SDR objects
    def version_description
      raise NotImplementedError
    end

    private

    attr_reader :repository_object
  end
end
