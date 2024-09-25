# frozen_string_literal: true

# Finds the constituents of a virtual object.
class VirtualObjectService
  def self.constituents(...)
    new(...).constituents
  end

  # @param [Cocina::Models::DRO] cocina_dro the cocina model for the virtual object
  # @param [Boolean] publishable when true, restrict to publishable items only
  # @return [Array<String>] the druids for the constituents of this virtual object
  def initialize(cocina_dro, publishable: false)
    @cocina_dro = cocina_dro
    @publishable = publishable
  end

  def constituents
    return [] unless cocina_dro.dro?

    RepositoryObject
      .joins(:head_version)
      .where(external_identifier: constituent_druids)
      .select(:external_identifier, :version, :head_version_id, :opened_version_id, :last_closed_version_id)
      .then { |constituents| publishable_constituents(constituents) }
      .map(&:external_identifier)
  end

  private

  attr_reader :cocina_dro, :publishable

  def constituent_druids
    cocina_dro.structural.hasMemberOrders.flat_map(&:members).uniq
  end

  def publishable_constituents(constituents)
    return constituents unless publishable

    constituents.select(&:publishable?)
  end
end
