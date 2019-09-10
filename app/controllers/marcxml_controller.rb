# frozen_string_literal: true

class MarcxmlController < ApplicationController #:nodoc:
  before_action :set_marcxml_resource

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  def catkey
    render plain: @marcxml.catkey
  end

  def marcxml
    render xml: @marcxml.marcxml
  end

  def mods
    render xml: @marcxml.mods
  end

  private

  def set_marcxml_resource
    @marcxml = MarcxmlResource.find_by(**marcxml_resource_params)
  end

  def marcxml_resource_params
    params.slice(:barcode, :catkey).to_unsafe_h.symbolize_keys
  end
end
