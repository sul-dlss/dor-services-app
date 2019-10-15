# frozen_string_literal: true

# API to move files to Stacks
class ShelvesController < ApplicationController
  before_action :load_item, only: :create

  # exception defined in application.rb;  see https://pdabrowski.com/blog/ruby-rescue-from-errors-with-grace
  rescue_from(DorServices::ContentDirNotFoundError) do |e|
    render status: :internal_server_error, plain: e.message
  end

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
