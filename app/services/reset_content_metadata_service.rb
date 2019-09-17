# frozen_string_literal: true

# Clears the contentMetadata datastream to the default, wiping out any members,
# and severing relationships bidirectionally.
#
# NOTE: item MUST allow modification, or `save!` will raise error
class ResetContentMetadataService
  DEFAULT_ITEM_TYPE = 'image'

  attr_reader :item, :type

  def initialize(item:, type: DEFAULT_ITEM_TYPE)
    @item = item
    @type = type
  end

  def reset
    disown_current_children!

    item.contentMetadata.content = "<contentMetadata objectId='#{item.id}' type='#{type}'/>"
    item.save!
  end

  private

  def disown_current_children!
    item.contentMetadata.ng_xml.xpath('//resource/relationship/@objectId').map(&:content).each do |child_id|
      child = Dor::Item.find(child_id)
      child.clear_relationship(:is_constituent_of)
      child.save! if child.relationships_are_dirty?
    end
  end
end
