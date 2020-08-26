# frozen_string_literal: true

module Cocina
  # Validates objects are valid
  class ObjectValidator
    def initialize(item)
      @item = item
    end

    attr_reader :error

    # @param [RequestAdminPolicy, RequestDRO, RequestCollection]
    def self.validate(obj)
      new(obj).validate
    end

    # @raises [ValidationError] if not valid
    def validate
      validator = Cocina::UniqueSourceIdValidator.new(item)
      raise ValidationError.new(validator.error, status: :conflict) unless validator.valid?

      validator = ValidateDarkService.new(item)
      raise ValidationError, validator.error unless validator.valid?

      validator = Cocina::ApoExistenceValidator.new(item)
      raise ValidationError, validator.error unless validator.valid?

      return if item.collection? || item.admin_policy?

      # Only DROs have collection membership
      validator = Cocina::CollectionExistenceValidator.new(item)
      raise ValidationError, validator.error unless validator.valid?
    end

    private

    attr_reader :item
  end
end
