# frozen_string_literal: true

class MarcxmlController < ApplicationController #:nodoc:
  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def catkey
    render plain: SymphonyReader.new(barcode: params[:barcode]).fetch_catkey
  rescue SymphonyReader::NotFound => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
  end

  def marcxml
    render xml: MarcxmlResource.new(barcode: params[:barcode], catkey: params[:catkey]).marcxml
  rescue SymphonyReader::NotFound => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
  end
end
