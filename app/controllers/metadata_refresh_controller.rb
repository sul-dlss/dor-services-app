# frozen_string_literal: true

# Gets the catkey or barcode from identityMetadata and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_item

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def refresh
    status = RefreshMetadataAction.run(@item)
    return render status: :internal_server_error, plain: "#{@item.pid} descMetadata missing required fields (<title>)" if missing_required_fields?

    @item.save! if status
  end

  private

  def missing_required_fields?
    @item.descMetadata.mods_title.blank?
  end
end
