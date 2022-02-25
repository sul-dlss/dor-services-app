# frozen_string_literal: true

# Responsible for retrieving information based on the given Dor::Item.
class ItemQueryService
  class UncombinableItemError < RuntimeError; end

  ALLOWED_WORKFLOW_STATES = %w[Accessioned Opened].freeze

  # @param [String] virtual_object a virtual_object druid
  # @param [Array] constituents a list of constituent druids
  # @return [Hash]
  def self.validate_combinable_items(virtual_object:, constituents:)
    errors = Hash.new { |hash, key| hash[key] = [] }

    errors[virtual_object] << "Item #{virtual_object} cannot be a constituent of itself" if constituents.include?(virtual_object)

    ([virtual_object] + constituents).each do |druid|
      find_combinable_item(druid)
    rescue UncombinableItemError => e
      errors[virtual_object] << e.message
    end

    errors
  end

  # @raise [UncombinableItemError] if the item is dark, citation_only, or not modifiable
  def self.find_combinable_item(druid)
    new(id: druid).item do |item|
      raise UncombinableItemError, "Item #{item.externalIdentifier} is not an item" unless item.dro?
      raise UncombinableItemError, "Item #{item.externalIdentifier} is dark" if item.access.access == 'dark'
      raise UncombinableItemError, "Item #{item.externalIdentifier} is citation-only" if item.access.access == 'citation-only'
      raise UncombinableItemError, "Item #{item.externalIdentifier} is itself a virtual object" if item.structural&.hasMemberOrders&.any? { |order| order.members.any? }
      raise UncombinableItemError, "Item #{item.externalIdentifier} is not in the accessioned or opened workflow state" unless current_workflow_state(item).in?(ALLOWED_WORKFLOW_STATES)
    end
  end

  def self.current_workflow_state(item)
    WorkflowClientFactory
      .build
      .status(druid: item.externalIdentifier, version: item.version)
      .display_simplified
  end
  private_class_method :current_workflow_state

  # @param [String] id - The id of the item
  def initialize(id:)
    @id = id
  end

  def item(&block)
    @cocina_item ||= CocinaObjectStore.find(id)
    return @cocina_item unless block

    @cocina_item.tap(&block)
  end

  private

  attr_reader :id
end
