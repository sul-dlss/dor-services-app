# frozen_string_literal: true

# Gets the catkey or barcode from identityMetadata and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_item

  def refresh
    status = RefreshMetadataAction.run(@item)
    @item.save if status
  end
end
