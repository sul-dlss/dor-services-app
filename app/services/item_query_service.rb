# frozen_string_literal: true

# Responsible for retrieving information based on the given Dor::Item.
class ItemQueryService
  class UncombinableItemError < RuntimeError; end

  # @param [String] id - The id of the item
  # @param [#exists?, #find] item_relation - How we will query some of the related information
  def initialize(id:, item_relation: default_item_relation)
    @id = id
    @item_relation = item_relation
  end

  # @param [String] parent a parent druid
  # @param [Array] children a list of child druids
  # @return [Hash]
  def self.validate_combinable_items(parent:, children:)
    errors = Hash.new { |hash, key| hash[key] = [] }

    ([parent] + children).each do |druid|
      find_combinable_item(druid)
    rescue UncombinableItemError => e
      errors[parent] << e.message
    end

    errors
  end

  # @raise [UncombinableItemError] if the item is dark, citation_only, or not modifiable
  def self.find_combinable_item(druid)
    query_service = ItemQueryService.new(id: druid)
    query_service.item do |item|
      workflow_errors = errors_for(item.id, item.current_version)
      raise UncombinableItemError, "Item #{item.pid} has workflow errors: #{workflow_errors.join('; ')}" if workflow_errors.any?
      raise UncombinableItemError, "Item #{item.pid} is not open or openable" unless VersionService.open?(item) || VersionService.can_open?(item)
      raise UncombinableItemError, "Item #{item.pid} is dark" if item.rightsMetadata.dra_object.dark?
      raise UncombinableItemError, "Item #{item.pid} is citation_only" if item.rightsMetadata.dra_object.citation_only?
    end
  end

  def self.errors_for(pid, version)
    Dor::Config.workflow.client.workflow_routes
               .all_workflows(pid: pid)
               .errors_for(version: version)
  end
  private_class_method :errors_for

  def item(&block)
    @item ||= item_relation.find(id)
    return @item unless block_given?

    @item.tap(&block)
  end

  private

  attr_reader :id, :item_relation

  def default_item_relation
    Dor::Item
  end
end
