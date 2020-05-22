# frozen_string_literal: true

class MarcxmlController < ApplicationController #:nodoc:
  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def catkey
    render plain: SymphonyReader.new(barcode: params[:barcode]).fetch_catkey
  end

  def marcxml
    render xml: MarcxmlResource.new(barcode: params[:barcode], catkey: params[:catkey]).marcxml
  end
end
