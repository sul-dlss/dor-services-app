# frozen_string_literal: true

# Gets the catkey or barcode from identityMetadata and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_cocina_object

  def refresh
    result = RefreshMetadataAction.run(identifiers: identifiers,
                                       cocina_object: @cocina_object, druid: @cocina_object.externalIdentifier)
    if result.failure?
      return json_api_error(status: :unprocessable_entity, title: 'No resolvable identifiers',
                            message: "#{@cocina_object.externalIdentifier} had no resolvable identifiers: #{identifiers.inspect}")
    end

    CocinaObjectStore.save(@cocina_object.new(description: result.value!.description_props))
  rescue MarcService::CatalogRecordNotFoundError => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
  rescue MarcService::MarcServiceError => e
    Honeybadger.notify(e)
    json_api_error(status: :internal_server_error, message: e.message)
  end

  private

  def identifiers
    return [] unless @cocina_object.identification&.catalogLinks

    @identifiers ||= @cocina_object.identification.catalogLinks.filter_map { |clink| "catkey:#{clink.catalogRecordId}" if clink.catalog == 'symphony' }.tap do |id|
      # Not all Cocina objects have identification metadata that includes barcodes (e.g., collections)
      next unless @cocina_object.identification.try(:barcode)

      id << "barcode:#{@cocina_object.identification.barcode}" if @cocina_object.identification.barcode
    end
  end
end
