# frozen_string_literal: true

class MarcxmlController < ApplicationController # :nodoc:
  def catkey
    render plain: SymphonyReader.new(barcode: params[:barcode]).fetch_catkey
  rescue SymphonyReader::NotFound => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
  rescue SymphonyReader::ResponseError => e
    json_api_error(status: :internal_server_error, message: e.message)
  end

  def marcxml
    render xml: MarcService.marcxml(barcode: params[:barcode], catkey: params[:catkey])
  rescue MarcService::CatalogRecordNotFoundError => e
    json_api_error(status: :bad_request, title: 'Record not found in Symphony', message: e.message)
  rescue MarcService::MarcServiceError => e
    json_api_error(status: :internal_server_error, message: e.message)
  end
end
