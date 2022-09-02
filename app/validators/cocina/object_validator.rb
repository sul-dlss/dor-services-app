# frozen_string_literal: true

module Cocina
  # Validates objects are valid
  class ObjectValidator
    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    attr_reader :error

    # @param [Cocina::Models::RequestAdminPolicy,Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,
    # Cocina::Models::DRO,Cocina::Models::AdminPolicy,Cocina::Models::Collection]
    # @raise [ValidationError] if not valid
    def self.validate(cocina_object)
      new(cocina_object).validate
    end

    # @raise [ValidationError] if not valid
    def validate # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
      validator = Cocina::ApoExistenceValidator.new(cocina_object)
      raise ValidationError, validator.error unless validator.valid?

      return unless cocina_object.dro?

      # Only DROs have collection membership
      validator = Cocina::CollectionExistenceValidator.new(cocina_object)
      raise ValidationError, validator.error unless validator.valid?

      # Only DROs have files
      validator = Cocina::FileHierarchyValidator.new(cocina_object)
      raise ValidationError, validator.error unless validator.valid?

      return if cocina_object.is_a?(Cocina::Models::RequestDRO) # RequestDROs have no identifiers to validate

      # A "soft" validation of file ids
      cocina_object.structural.contains.each do |file_set|
        file_set.structural.contains.each do |file|
          next if Cocina::IdGenerator.valid_file_id?(file.externalIdentifier)

          Honeybadger.notify(
            "File ID is not in the expected format. It should begin with #{Cocina::IdGenerator::ID_NAMESPACE}",
            context: { file_id: file.externalIdentifier, external_identifier: cocina_object.externalIdentifier }
          )
        end
      end
    end

    private

    attr_reader :cocina_object

    def request?
      !cocina_object.respond_to?(:externalIdentifier)
    end
  end
end
