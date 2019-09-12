# frozen_string_literal: true

# Manages the embargo for a repository object
class EmbargoesController < ApplicationController
  before_action :load_item, only: [:show, :update]

  def show
    result = { embargoed: !!@item&.embargoed?, release_date: @item&.embargoMetadata&.release_date }
    render status: :ok, json: result.to_json
  end

  def update
    # validate that the embargo_date and requesting_user parameters were provided
    params.require([:embargo_date, :requesting_user])
    Dor::EmbargoService.new(@item).update(Date.parse(params[:embargo_date]))
    @item.events.add_event('Embargo', params[:requesting_user], 'Embargo date modified')
    head :no_content
  rescue ArgumentError => e
    render status: :unprocessable_entity, plain: e.message
  end
end
