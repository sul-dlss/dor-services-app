# frozen_string_literal: true

# Lists the valid event types
class EventTypesController < ApplicationController
  def index
    render json: Event::EVENT_TYPES.sort
  end
end
