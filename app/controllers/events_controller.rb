# frozen_string_literal: true

# A RESTful controller for Event records
class EventsController < ApplicationController
  def index
    @events = filter(Event.where(druid: params[:object_id]).order(created_at: :desc))
  rescue Date::Error => e
    render_bad_request(e.message)
  end

  def create
    params.require(:event_type)
    Event.create!(druid: params[:object_id], event_type: params[:event_type], data: params[:data])
    head :created
  rescue ActiveRecord::RecordInvalid => e
    render_bad_request(e.message)
  end

  private

  def filter(events)
    events = events.where(event_type: params[:event_types]) if params[:event_types].present?
    events = events.where(created_at: created_at_range) if params[:from].present? || params[:to].present?
    events
  end

  # from is inclusive and to is exclusive; either may be omitted
  def created_at_range
    from = parse_time(:from) if params[:from].present?
    to = parse_time(:to) if params[:to].present?
    from...to
  end

  def parse_time(param)
    DateTime.iso8601(params[param]).utc
  rescue Date::Error
    raise Date::Error, "#{param} must be an ISO 8601 date or date-time"
  end

  def render_bad_request(message)
    render json: {
      errors: [
        { title: 'bad request', detail: message }
      ]
    }, status: :bad_request
  end
end
