# frozen_string_literal: true

module Cocina
  # Validates objects are valid
  class ObjectValidator
    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    attr_reader :error

    # @param [Cocina::Models::RequestAdminPolicy,Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::DRO,Cocina::Models::AdminPolicy,Cocina::Models::Collection]
    # @raise [ValidationError] if not valid
    def self.validate(cocina_object)
      new(cocina_object).validate
    end

    # @raise [ValidationError] if not valid
    def validate
      validator = Cocina::ApoExistenceValidator.new(cocina_object)
      raise ValidationError, validator.error unless validator.valid?

      return unless cocina_object.dro?

      # Only DROs have collection membership
      validator = Cocina::CollectionExistenceValidator.new(cocina_object)
      raise ValidationError, validator.error unless validator.valid?

      # Only DROs have files
      validator = Cocina::FileHierarchyValidator.new(cocina_object)
      raise ValidationError, validator.error unless validator.valid?
    end

    private

    attr_reader :cocina_object

    def request?
      !cocina_object.respond_to?(:externalIdentifier)
    end
  end
end
