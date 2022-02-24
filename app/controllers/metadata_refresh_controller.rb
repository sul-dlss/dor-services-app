# frozen_string_literal: true

# Gets the catkey or barcode from identityMetadata and returns the catalog info
class MetadataRefreshController < ApplicationController
  before_action :load_cocina_object, only: :refresh

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def refresh
    descriptive_props = RefreshMetadataAction.run(identifiers: identifiers,
                                                  pid: @cocina_object.externalIdentifier)

    return render status: :unprocessable_entity, plain: "#{@cocina_object.externalIdentifier} had no resolvable identifiers: #{identifiers.inspect}" unless descriptive_props

    CocinaObjectStore.save(@cocina_object.new(description: descriptive_props))
  rescue Dry::Struct::Error => e
    json_api_error(status: :unprocessable_entity, title: 'Unable to transform MODS', message: e.message)
  rescue SymphonyReader::NotFound => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
  end

  private

  def identifiers
    @identifiers ||= begin
      result = Array(@cocina_object.identification&.catalogLinks).filter_map { |link| "catkey:#{link.catalogRecordId}" if link.catalog == 'symphony' }
      result += ["barcode:#{@cocina_object.identification.barcode}"] if @cocina_object.identification&.barcode
      result
    end
  end
end
