# frozen_string_literal: true

module Migrators
  # Base migrator.
  # Depends on logic in bin/migrate-cocina which may also open/close versions, validate cocina, and save objects.
  class Base
    # Return an array of druids to be migrated, or nil if all druids should be migrated.
    def self.druids
      nil
    end

    # @param repository_object - a RepositoryObject instance
    def initialize(repository_object)
      @repository_object = repository_object
    end

    # A migrator must implement a migrate? method that returns true if the SDR object should be migrated.
    def migrate?
      raise NotImplementedError
    end

    # A migrator must implement a migrate method that migrates (mutates) the RepositoryObject instance
    def migrate
      raise NotImplementedError
    end

    # subclass can override if a different way of referencing the updated version was used
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
