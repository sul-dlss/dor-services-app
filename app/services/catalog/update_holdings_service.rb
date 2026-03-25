# frozen_string_literal: true

module Catalog
  # Updates FOLIO holdings record based on release.
  class UpdateHoldingsService
    def self.update(cocina_object)
      new(cocina_object).update
    end

    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    def update
      return if cocina_object.admin_policy?
      return unless cocina_object.identification.catalogLinks.any? { |link| link.catalog == 'folio' }

      HoldingsGenerator.manage_holdings(cocina_object)
    end

    private

    attr_reader :cocina_object
  end
end
