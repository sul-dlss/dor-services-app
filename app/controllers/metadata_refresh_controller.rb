# frozen_string_literal: true

# Given a cocina object, fetch the available refreshable catkey or barcodes and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_cocina_object

  def refresh
    result = RefreshMetadataAction.run(identifiers:,
                                       cocina_object: @cocina_object, druid: @cocina_object.externalIdentifier)
    if result.failure?
      return json_api_error(status: :unprocessable_entity, title: 'No available catkeys or barcodes',
                            message: "#{@cocina_object.externalIdentifier} had no catkeys marked as refreshable: #{identifiers.inspect}")
    end

    UpdateObjectService.update(@cocina_object.new(description: result.value!.description_props))
  rescue Catalog::MarcService::CatalogRecordNotFoundError => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
  rescue Catalog::MarcService::MarcServiceError => e
    Honeybadger.notify(e)
    json_api_error(status: :internal_server_error, message: e.message)
  end

  private

  def identifiers
    RefreshMetadataAction.identifiers(cocina_object: @cocina_object).tap do |id|
      # Not all Cocina objects have identification metadata that includes barcodes (e.g., collections)
      next unless @cocina_object.identification.try(:barcode)

      id << "barcode:#{@cocina_object.identification.barcode}" if @cocina_object.identification.barcode
    end
  end
end
