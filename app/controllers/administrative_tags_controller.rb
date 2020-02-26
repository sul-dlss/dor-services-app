# frozen_string_literal: true

# Administrative tags controller (nested resource under objects)
class AdministrativeTagsController < ApplicationController
  before_action :load_item

  rescue_from(ActiveFedora::ObjectNotFoundError) do |e|
    render status: :not_found, plain: e.message
  end

  # Show administrative tags for an object
  def show
    render json: AdministrativeTags.for(item: @item)
  end

  def create
    AdministrativeTags.create(item: @item, tags: params.require(:administrative_tags))
    head :created
  end
end
