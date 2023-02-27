# frozen_string_literal: true

module Migrators
  # Base migrator.
  class Base
    # Return an array of druids to be migrated, or nil if all druids should be migrated.
    def self.druids
      nil
    end

    # @param ar_cocina_object - an ActiveRecord object pertaining to a cocina object (Dro, AdminPolicy, or Collection)
    def initialize(ar_cocina_object)
      @ar_cocina_object = ar_cocina_object
    end

    # A migrator must implement a migrate? method that returns true if the SDR object should be migrated.
    def migrate?
      raise NotImplementedError
    end

    # A migrator must implement a migrate method that migrates (mutates) the ActiveRecord cocina object.
    def migrate
      raise NotImplementedError
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
    # A migrator may override the version_description method to provide a version description for versionined SDR objects
    def version_description
      raise NotImplementedError
    end

    protected

    attr_reader :ar_cocina_object
  end
end
