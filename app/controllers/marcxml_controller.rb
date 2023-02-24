# frozen_string_literal: true

class MarcxmlController < ApplicationController # :nodoc:
  def marcxml
    render xml: Catalog::MarcService.marcxml(barcode: params[:barcode], catkey: params[:catkey])
  rescue Catalog::MarcService::CatalogRecordNotFoundError => e
    json_api_error(status: :bad_request, title: 'Record not found in Symphony', message: e.message)
  rescue Catalog::MarcService::MarcServiceError => e
    json_api_error(status: :internal_server_error, message: e.message)
  end
end
