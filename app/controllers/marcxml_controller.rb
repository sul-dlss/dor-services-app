# frozen_string_literal: true

class MarcxmlController < ApplicationController #:nodoc:
  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def catkey
    render plain: SymphonyReader.new(**marcxml_resource_params).fetch_catkey
  end

  def marcxml
    render xml: MarcxmlResource.find_by(**marcxml_resource_params).marcxml
  end

  private

  def marcxml_resource_params
    params.permit(:barcode, :catkey).to_unsafe_h.symbolize_keys
  end
end
