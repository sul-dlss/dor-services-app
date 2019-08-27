# frozen_string_literal: true

# Clears the contentMetadata datastream to the default, wiping out any members.
class ResetContentMetadataService
  def initialize(druid:, type: 'image')
    @druid = druid
    @type = type
  end

  def reset
    work = ItemQueryService.find_modifiable_item(@druid)
    work.contentMetadata.content = "<contentMetadata objectId='#{work.id}' type='#{@type}'/>"
    work.save!
  end
end
