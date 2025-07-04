# frozen_string_literal: true

# A RESTful controller for Event records
class EventsController < ApplicationController
  def index
    @events = Event.where(druid: params[:object_id]).order(created_at: :desc)
    @events = @events.where(event_type: params[:event_types]) if params[:event_types].present?
  end

  def create
    params.require(:event_type)
    Event.create!(druid: params[:object_id], event_type: params[:event_type], data: params[:data])
    head :created
  end
end
