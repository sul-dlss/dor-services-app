# frozen_string_literal: true

# Release tags controller (nested resource under objects)
class ReleaseTagsController < ApplicationController
  before_action :load_item

  rescue_from(ActiveFedora::ObjectNotFoundError) do |e|
    render status: :not_found, plain: e.message
  end

  # Show release tags for an object and for all the collections that it belongs to
  def show
    render json: ReleaseTags.for(item: @item)
  end

  # You can post a release tag as JSON in the body to add a release tag to an item.
  # If successful it will return a 201 code, otherwise the error that occurred will bubble to the top
  #
  # 201
  def create
    ReleaseTags.create(@item, create_parameters)
    Persister.store(@item)
    head :created
  end

  private

  def create_parameters
    params.permit(:release, :what, :to, :who, :when).to_h
  end
end
