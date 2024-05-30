# frozen_string_literal: true

# Finds the constituents of a virtual object.
class VirtualObjectService
  def self.constituents(...)
    new(...).constituents
  end

  # @param [Cocina::Models::DRO] cocina_dro the cocina model for the virtual object
  # @param [Boolean] only_published when true, restrict to only published items
  # @param [Boolean] exclude_opened when true, exclude opened items
  # @return [Array<String>] the druids for the constituents of this virtual object
  def initialize(cocina_dro, only_published: false, exclude_opened: false)
    @cocina_dro = cocina_dro
    @only_published = only_published
    @exclude_opened = exclude_opened
  end

  def constituents
    return [] unless cocina_dro.dro?

    RepositoryObject.joins(:head_version).where(external_identifier: constituent_druids).select(:external_identifier, :version, :head_version_id, :opened_version_id)
                    .then { |constituents| exclude_opened_constituents(constituents) }
                    .then { |constituents| only_published_constituents(constituents) }
                    .map(&:external_identifier)
  end

  private

  attr_reader :cocina_dro, :only_published, :exclude_opened

  def constituent_druids
    cocina_dro.structural.hasMemberOrders.flat_map(&:members).uniq
  end

  def exclude_opened_constituents(constituents)
    return constituents unless exclude_opened

    constituents.reject(&:open?)
  end

  def only_published_constituents(constituents)
    return constituents unless only_published

    constituents.select do |constituent|
      WorkflowStateService.published?(druid: constituent.external_identifier, version: constituent.version)
    end
  end
end
