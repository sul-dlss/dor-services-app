# frozen_string_literal: true

# Gets the catkey or barcode from identityMetadata and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_cocina_object

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def refresh
    updated_cocina_object = RefreshMetadataAction.run(identifiers: identifiers,
                                                      cocina_object: @cocina_object)
    return render status: :unprocessable_entity, plain: "#{@cocina_object.externalIdentifier} had no resolvable identifiers: #{identifiers.inspect}" unless updated_cocina_object

    CocinaObjectStore.save(updated_cocina_object)
  rescue SymphonyReader::NotFound => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
  end

  private

  def identifiers
    return [] unless @cocina_object.identification&.catalogLinks

    @identifiers ||= @cocina_object.identification.catalogLinks.filter_map { |clink| "catkey:#{clink.catalogRecordId}" if clink.catalog == 'symphony' }.tap do |id|
      id << "barcode:#{@cocina_object.identification.barcode}" if @cocina_object.identification.barcode
    end
  end
end
