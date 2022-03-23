# frozen_string_literal: true

# Gets the catkey or barcode from identityMetadata and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_cocina_object

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def refresh
    result = RefreshMetadataAction.run(identifiers: identifiers,
                                       cocina_object: @cocina_object, druid: @cocina_object.externalIdentifier)
    return render status: :unprocessable_entity, plain: "#{@cocina_object.externalIdentifier} had no resolvable identifiers: #{identifiers.inspect}" if result.failure?

    CocinaObjectStore.save(@cocina_object.new(description: result.value!.description_props))
  rescue SymphonyReader::NotFound => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
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
