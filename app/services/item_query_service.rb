# frozen_string_literal: true

# Responsible for retrieving information based on the given Dor::Item.
class ItemQueryService
  class UncombinableItemError < RuntimeError; end

  # @param [String] virtual_object a virtual_object druid
  # @param [Array] constituents a list of constituent druids
  # @return [Hash]
  def self.validate_combinable_items(virtual_object:, constituents:)
    errors = Hash.new { |hash, key| hash[key] = [] }

    errors[virtual_object] << "Item #{virtual_object} cannot be a constituent of itself" if constituents.include?(virtual_object)

    # check virtual_object for combinability
    begin
      find_combinable_item(virtual_object)
      check_open(virtual_object)
    rescue UncombinableItemError => e
      errors[virtual_object] << e.message
    end

    # check constituents for combinability and whether they are already virtual objects
    constituents.each do |druid|
      check_virtual(druid)
      check_accessioned(druid)
      find_combinable_item(druid)
    rescue UncombinableItemError => e
      errors[virtual_object] << e.message
    end

    errors
  end

  # @raise [UncombinableItemError] if the item is not an item, dark, or citation_only
  def self.find_combinable_item(druid)
    new(id: druid).item do |item|
      raise UncombinableItemError, "Item #{item.externalIdentifier} is not an item" unless item.dro?
      raise UncombinableItemError, "Item #{item.externalIdentifier} is dark" if item.access.view == 'dark'
      raise UncombinableItemError, "Item #{item.externalIdentifier} is citation-only" if item.access.view == 'citation-only'
    end
  end

  # @raise [UncombinableItemError] if druid is a virtual object
  def self.check_virtual(druid)
    new(id: druid).item do |item|
      raise UncombinableItemError, "Item #{item.externalIdentifier} is itself a virtual object" if item.structural&.hasMemberOrders&.any? { |order| order.members.any? }
    end
  end
  private_class_method :check_virtual

  # @raise [UncombinableItemError] if the items is not open or openable
  def self.check_open(druid)
    new(id: druid).item do |item|
      raise UncombinableItemError, "Item #{item.externalIdentifier} is not open or openable" unless VersionService.open?(druid: item.externalIdentifier, version: item.version) || VersionService.can_open?(druid: item.externalIdentifier, version: item.version)
    end
  end

  # @raise [UncombinableItemError] if the item is dark, citation_only, or not modifiable
  def self.check_accessioned(druid)
    new(id: druid).item do |item|
      raise UncombinableItemError, "Item #{item.externalIdentifier} has not been accessioned" unless WorkflowStateService.accessioned?(druid: item.externalIdentifier, version: item.version)
    end
  end

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
