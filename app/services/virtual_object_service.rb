# frozen_string_literal: true

# Finds the constituents of a virtual object.
class VirtualObjectService
  def self.constituents(...)
    new(...).constituents
  end

  # @param [Cocina::Models::DRO] cocina_item the cocina model for the virtual object
  # @param [Boolean] publishable when true, restrict to publishable items only
  # @return [Array<String>] the druids for the constituents of this virtual object
  def initialize(cocina_item, publishable: false)
    @cocina_item = cocina_item
    @publishable = publishable
  end

  def constituents
    return [] unless cocina_item.dro?

    RepositoryObject
      .currently_has_constituents(constituent_druids)
      .then { |constituents| only_publishable? ? constituents.select(&:publishable?) : constituents }
      .pluck(:external_identifier)
  end

  private

  attr_reader :cocina_item

  def only_publishable?
    @publishable
  end

  def constituent_druids
    cocina_item.structural.hasMemberOrders.flat_map(&:members).uniq
  end
end
