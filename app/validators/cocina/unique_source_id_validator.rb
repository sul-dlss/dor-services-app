# frozen_string_literal: true

module Cocina
  # Validates that the sourceId attribute for a new DRO has not been used before
  class UniqueSourceIdValidator
    # @param [#dro?] item to be validated
    def initialize(item)
      @item = item
    end

    attr_reader :error

    # @return [Boolean] true if not a DRO (no validation necessary) or if the sourceId is unique.
    def valid?
      return true unless meets_preconditions?

      @error = "An object (#{duplicate_druid}) with the source ID '#{item.identification.sourceId}' has already been registered." if duplicate_druid

      @error.nil?
    end

    private

    attr_reader :item

    def duplicate_druid
      unless @already_ran
        @duplicate_druid = lookup_duplicate
        # we keep track of @already_ran because lookup_duplicate could return nil
        # and we don't want to keep looking it up
        @already_ran = true
      end

      @duplicate_druid
    end

    def lookup_duplicate
      Dor::SearchService.query_by_id(item.identification.sourceId).first
    end

    def meets_preconditions?
      item.dro?
    end
  end
end
