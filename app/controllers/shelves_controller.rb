# frozen_string_literal: true

# API to move files to Stacks
class ShelvesController < ApplicationController
  before_action :load_item, only: :create

  def create
    if @item.is_a?(Dor::Item)
      ShelvingService.shelve(@item)
      head :no_content
    else
      render json: {
        errors: [
          { title: 'Invalid item type', detail: "A Dor::Item is required but you provided '#{@item.class}'" }
        ]
      }, status: :unprocessable_entity
    end
  end
end
