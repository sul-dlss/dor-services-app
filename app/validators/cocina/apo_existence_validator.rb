# frozen_string_literal: true

module Cocina
  # Validates that the hasAdminPolicy property references an AdminPolicyObject
  class ApoExistenceValidator
    def initialize(item)
      @item = item
    end

    attr_reader :error

    # @return [Boolean] true if not a DRO (no validation necessary) or if the sourceId is unique.
    def valid?
      begin
        apo = Dor.find(item.administrative.hasAdminPolicy)
        @error = "Expected '#{item.administrative.hasAdminPolicy}' to be an AdminPolicy but it is a #{apo.class}" unless apo.is_a?(Dor::AdminPolicyObject)
      rescue ActiveFedora::ObjectNotFoundError
        @error = "Unable to find adminPolicy '#{item.administrative.hasAdminPolicy}'"
      end

      @error.nil?
    end

    private

    attr_reader :item
  end
end
