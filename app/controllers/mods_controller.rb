# frozen_string_literal: true

# A controller for the MODS data on an object
class ModsController < ApplicationController
  before_action :load_cocina_object

  def show
    render xml: Cocina::Models::Mapping::ToMods::Description.transform(@cocina_object.description, @cocina_object.externalIdentifier).to_xml
  end
end
