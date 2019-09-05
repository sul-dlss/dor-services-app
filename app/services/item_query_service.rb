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

  delegate :allows_modification?, to: :item

  # @param [Array] druids a list of druids
  def self.validate_combinable_items(druids)
    errors = {}

    druids.each do |druid|
      find_combinable_item(druid)
    rescue UncombinableItemError => e
      errors[druid] = e.message
    end

    errors
  end

  # @raises [UncombinableItemError] if the item is dark, citation_only, or not modifiable
  def self.find_combinable_item(druid)
    query_service = ItemQueryService.new(id: druid)
    query_service.item do |item|
      raise UncombinableItemError, "Item #{item.pid} is not open for modification" unless query_service.allows_modification?
      raise UncombinableItemError, "Item #{item.pid} is dark" if item.rightsMetadata.dra_object.dark?
      raise UncombinableItemError, "Item #{item.pid} is citation_only" if item.rightsMetadata.dra_object.citation_only?
    end
  end

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
