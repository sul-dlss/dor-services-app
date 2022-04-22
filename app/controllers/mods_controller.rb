# frozen_string_literal: true

# A controller for the MODS data on an object
class ModsController < ApplicationController
  before_action :load_cocina_object

  def show
    render xml: Cocina::Models::Mapping::ToMods::Description.transform(@cocina_object.description, @cocina_object.externalIdentifier).to_xml
  end

  def update
    props = Cocina::Models::Mapping::FromMods::Description.props(mods: Nokogiri::XML(request.body.read), druid: @cocina_object.externalIdentifier, label: @cocina_object.label)
    updated_cocina_object = @cocina_object.new(description: props)
    CocinaObjectStore.save(updated_cocina_object)
  rescue Cocina::Models::ValidationError => e
    json_api_error(status: :bad_request, message: e.message)
  end
end
