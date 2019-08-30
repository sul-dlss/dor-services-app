# frozen_string_literal: true

# Gets the catkey or barcode from identityMetadata and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_item

  rescue_from(SymphonyReader::RecordIncompleteError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def refresh
    status = RefreshMetadataAction.run(@item)
    @item.save if status
  end
end
