# frozen_string_literal: true

module Cocina
  # Validates that the administrative.hasAdminPolicy property references an AdminPolicyObject
  class ApoExistenceValidator
    def initialize(item)
      @apo_id = item.administrative.hasAdminPolicy
    end

    attr_reader :error

    # @return [Boolean] false if the APO is not in the repository
    def valid?
      begin
        apo = Dor.find(apo_id)
        @error = "Expected '#{apo_id}' to be an AdminPolicy but it is a #{apo.class}" unless apo.is_a?(Dor::AdminPolicyObject)
      rescue ActiveFedora::ObjectNotFoundError
        @error = "Unable to find adminPolicy '#{apo_id}'"
      end

      @error.nil?
    end

    private

    attr_reader :apo_id
  end
end
