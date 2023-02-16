# frozen_string_literal: true

# Clears member orders from structural metadata within the Cocina cocina_item data model and adds new constituents
class ResetContentMetadataService
  def self.reset(cocina_item:, constituent_druids: [])
    new(cocina_item:).reset(constituent_druids:)
  end

  MAX_MEMBER_ORDERS = 1

  attr_reader :cocina_item, :notifier

  def initialize(cocina_item:)
    @cocina_item = cocina_item
    @notifier = DataErrorNotifier.new(druid: cocina_item.externalIdentifier)
  end

  # @return [Cocina::Models::DRO] updated cocina object
  def reset(constituent_druids: [])
    flag_multiple_member_orders!

    cocina_item.new(
      structural: structural.new(
        hasMemberOrders: Array.wrap(new_member_orders(constituent_druids))
      )
    )
  end

  private

  def flag_multiple_member_orders!
    return if member_orders_count <= MAX_MEMBER_ORDERS

    notifier.error("item #{cocina_item.externalIdentifier} has multiple member orders")
  end

  def member_orders_count
    return 0 if member_orders.nil?

    member_orders.count
  end

  def member_orders
    cocina_item.structural&.hasMemberOrders
  end

  def member_order
    Array.wrap(member_orders).first
  end

  def new_member_orders(constituent_druids)
    return if constituent_druids.empty? && member_order.to_h.keys.in?([[], [:members]])

    member_order.to_h.merge(members: constituent_druids)
  end

  def structural
    cocina_item.structural || Cocina::Models::DROStructural
  end
end
