# frozen_string_literal: true

# A controller for the MODS data on an object
class ModsController < ApplicationController
  before_action :load_cocina_object

  def show
    render xml: Cocina::ToFedora::Descriptive.transform(@cocina_object.description, @cocina_object.externalIdentifier).to_xml
  end

  def update
    props = Cocina::FromFedora::Descriptive.props(mods: Nokogiri::XML(request.body.read), druid: @cocina_object.externalIdentifier)
    updated_cocina_object = @cocina_object.new(description: props)
    CocinaObjectStore.save(updated_cocina_object)
  rescue Cocina::Models::ValidationError => e
    json_api_error(status: :bad_request, message: e.message)
  end
end
