# frozen_string_literal: true

module Migrators
  # Base migrator.
  class Base
    # Return an array of druids to be migrated, or nil if all druids should be migrated.
    def self.druids
      nil
    end

    # A migrator must implement a constructor that takes an ActiveRecord Dro, AdminPolicy, or Collection.
    def initialize(obj)
      # This is an ActiveRecord object, not a Cocina object.
      @obj = obj
    end

    # A migrator must implement a migrate? method that returns true if the object should be migrated.
    def migrate?
      raise NotImplementedError
    end

    # A migrator must implement a migrate method that migrates (mutates) the object.
    def migrate
      raise NotImplementedError
    end

    def publish?
      false
    end

    def version?
      false
    end

    def version_description
      raise NotImplementedError
    end

    protected

    attr_reader :obj
  end
end
