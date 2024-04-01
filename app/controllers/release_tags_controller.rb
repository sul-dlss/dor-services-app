# frozen_string_literal: true

# Provides an API for release tags
class ReleaseTagsController < ApplicationController
  before_action :load_cocina_object, only: [:index, :create]

  rescue_from(CocinaObjectStore::CocinaObjectNotFoundError) do |e|
    json_api_error(status: :not_found, message: e.message)
  end

  def index
    render json: ReleaseTagService.item_tags(cocina_object: @cocina_object)
  end

  def create
    ReleaseTagService.create(cocina_object: @cocina_object, tag: new_tag)
    head :created
  end

  private

  def new_tag
    Cocina::Models::ReleaseTag.new(
      to: params['to'],
      who: params['who'],
      what: params['what'],
      release: ActiveModel::Type::Boolean.new.cast(params['release']),
      date: DateTime.now.utc.iso8601
    )
  end
end
