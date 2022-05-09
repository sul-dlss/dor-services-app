# frozen_string_literal: true

module Cocina
  # Validates that the administrative.hasAdminPolicy property references an AdminPolicyObject
  class ApoExistenceValidator
    def initialize(cocina_object)
      @apo_id = cocina_object.administrative.hasAdminPolicy
    end

    attr_reader :error

    # @return [Boolean] false if the APO is not in the repository
    def valid?
      # Always valid if UR APO
      return true if apo_id == Settings.ur_admin_policy.druid

      begin
        apo = CocinaObjectStore.find(apo_id)
        @error = "Expected '#{apo_id}' to be an AdminPolicy but it is a #{apo.class}" unless apo.admin_policy?
      rescue CocinaObjectStore::CocinaObjectNotFoundError
        @error = "Unable to find adminPolicy '#{apo_id}'"
      end

      @error.nil?
    end

    private

    attr_reader :apo_id
  end
end
