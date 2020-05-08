# frozen_string_literal: true

# Administrative tags controller (nested resource under objects)
class AdministrativeTagsController < ApplicationController
  before_action :load_item

  rescue_from(ActiveFedora::ObjectNotFoundError) do |e|
    render status: :not_found, plain: e.message
  end

  # Show administrative tags for an object
  def index
    render json: AdministrativeTags.for(item: @item)
  end

  def create
    AdministrativeTags.create(item: @item,
                              tags: params.require(:administrative_tags),
                              replace: params[:replace])
  rescue ActiveRecord::RecordInvalid => e
    render status: :conflict, plain: e.message
  else
    head :created
  end

  def update
    AdministrativeTags.update(item: @item,
                              current: CGI.unescape(params[:id]),
                              new: params.require(:administrative_tag))
  rescue ActiveRecord::RecordNotFound => e
    render status: :not_found, plain: e.message
  rescue ActiveRecord::RecordInvalid => e
    render status: :conflict, plain: e.message
  else
    head :no_content
  end

  def destroy
    AdministrativeTags.destroy(item: @item, tag: CGI.unescape(params[:id]))
  rescue ActiveRecord::RecordNotFound => e
    render status: :not_found, plain: e.message
  else
    head :no_content
  end
end
