# frozen_string_literal: true

# Clears member orders from structural metadata within the Cocina cocina_item data model and adds new constituents
class ResetContentMetadataService
  def self.reset(cocina_item:, constituent_druids: [])
    new(cocina_item:).reset(constituent_druids:)
  end

  attr_reader :cocina_item, :notifier

  def initialize(cocina_item:)
    @cocina_item = cocina_item
    @notifier = DataErrorNotifier.new(druid: cocina_item.externalIdentifier)
  end

  # @return [Cocina::Models::DRO] updated cocina object
  def reset(constituent_druids: [])
    flag_multiple_member_orders!

    member_orders = if constituent_druids.empty?
                      empty_member_orders
                    else
                      empty_member_orders + regenerated_member_order(constituent_druids)
                    end

    cocina_item.new(structural: new_structural(member_orders))
  end

  private

  def flag_multiple_member_orders!
    member_orders = cocina_item.structural&.hasMemberOrders&.count { |order| order.members.any? }
    return if member_orders.nil? || member_orders < 2

    notifier.error("item #{cocina_item.externalIdentifier} has multiple member orders")
  end

  def empty_member_orders
    Array(cocina_item.structural&.hasMemberOrders&.select { |order| order.members.empty? })
  end

  def new_structural(member_orders)
    return Cocina::Models::DROStructural.new(hasMemberOrders: member_orders) if cocina_item.structural.nil?

    cocina_item.structural.new(
      hasMemberOrders: member_orders
    )
  end

  def regenerated_member_order(constituent_druids)
    [
      {
        members: constituent_druids
      }
    ]
  end
end
