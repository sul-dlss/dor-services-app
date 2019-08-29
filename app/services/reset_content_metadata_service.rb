# frozen_string_literal: true

# Clears the contentMetadata datastream to the default, wiping out any members.
# item MUST allow modification, or save! will raise error
class ResetContentMetadataService
  def initialize(item:, type: 'image')
    @item = item
    @type = type
  end

  def reset
    @item.contentMetadata.content = "<contentMetadata objectId='#{@item.id}' type='#{@type}'/>"
    @item.save!
  end
end
