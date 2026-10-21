# frozen_string_literal: true

# Given a cocina object, fetch the available refreshable catalogRecordId or barcodes and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_cocina_object

  def refresh
    result = RefreshDescriptionFromCatalog.run(
      cocina_object: @cocina_object, druid: @cocina_object.externalIdentifier, use_barcode: false
    )
    if result.failure?
      return json_api_error(status: :unprocessable_content, title: 'No available catalog link or barcodes',
                            message: "#{@cocina_object.externalIdentifier} has no catalog links marked as refreshable")
    end

    # NOTE: we've already refreshed description above explicitly, we don't want the job to do another folio refresh
    # Why not just skip the refresh above and let the job auto handle it?
    # Because (1) auto-refresh is behind a feature flag and it might be false (and this is a user requested refresh)
    # and (2) we want to catch a failure in the refresh above immediately and return a 422 error
    UpdateObjectService.update(cocina_object: @cocina_object.new(description: result.value!.description_props),
                               auto_refresh_description: false)
  rescue Catalog::Errors::RecordNotFoundError => e
    json_api_error(status: :bad_request, title: 'Not found in catalog', message: e.message)
  rescue Catalog::Errors::BaseError => e
    Honeybadger.notify(e)
    json_api_error(status: :internal_server_error, message: e.message)
  rescue Cocina::Models::ValidationError => e
    json_api_error(status: :unprocessable_content, title: 'Cocina validation error', message: e.message)
  end
end
