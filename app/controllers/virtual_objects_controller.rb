# frozen_string_literal: true

# Create virtual objects
class VirtualObjectsController < ApplicationController
  before_action :validate_from_openapi

  rescue_from(JSONSchemer::Rails::RequestValidationError) do |e|
    json_api_error(status: :bad_request, message: e.message)
  end

  # Create one or more virtual objects represented by JSON
  def create
    result = BackgroundJobResult.create
    CreateVirtualObjectsJob.perform_later(virtual_objects: create_params[:virtual_objects],
                                          background_job_result: result)
    head :created, location: result
  end

  private

  def create_params
    params.to_unsafe_h
  end
end
