# frozen_string_literal: true

# Gets the catkey or barcode from identityMetadata and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_item

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def refresh
    status = RefreshMetadataAction.run(identifiers: identifiers,
                                       datastream: @item.descMetadata)
    return render status: :unprocessable_entity, plain: "#{@item.pid} had no resolvable identifiers: #{identifiers.inspect}" unless status
    return render status: :internal_server_error, plain: "#{@item.pid} descMetadata missing required fields (<title>)" if missing_required_fields?

    Persister.store(@item)
  end

  private

  def identifiers
    @identifiers ||= @item.identityMetadata.otherId.collect(&:to_s)
  end

  def missing_required_fields?
    @item.descMetadata.mods_title.blank?
  end
end
