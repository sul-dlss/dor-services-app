# frozen_string_literal: true

# Given a cocina object, fetch the available refreshable catalogRecordId or barcodes and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_cocina_object

  def refresh
    result = RefreshDescriptionFromCatalog.run(
      cocina_object: @cocina_object, druid: @cocina_object.externalIdentifier, use_barcode: true
    )
    if result.failure?
      return json_api_error(status: :unprocessable_content, title: 'No available catalog link or barcodes',
                            message: "#{@cocina_object.externalIdentifier} has no catalog links marked as refreshable")
    end

    UpdateObjectService.update(cocina_object: @cocina_object.new(description: result.value!.description_props))
  rescue Catalog::MarcService::CatalogRecordNotFoundError => e
    json_api_error(status: :bad_request, title: 'Not found in catalog', message: e.message)
  rescue Catalog::MarcService::MarcServiceError => e
    Honeybadger.notify(e)
    json_api_error(status: :internal_server_error, message: e.message)
  rescue Cocina::Models::ValidationError => e
    json_api_error(status: :unprocessable_content, title: 'Cocina validation error', message: e.message)
  end
end
