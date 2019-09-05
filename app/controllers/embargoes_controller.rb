# frozen_string_literal: true

# Manages the embargo for a repository object
class EmbargoesController < ApplicationController
  before_action :load_item, only: :update

  def update
    # validate that the embargo_date and requesting_user parameters were provided
    params.require([:embargo_date, :requesting_user])
    Dor::EmbargoService.new(@item).update(params[:embargo_date])
    @item.events.add_event('Embargo', params[:requesting_user], 'Embargo date modified')
    head :no_content
  rescue ArgumentError => e
    render status: 422, plain: e.message
  end
end
