# frozen_string_literal: true

# Create virtual objects
class VirtualObjectsController < ApplicationController
  # Create one or more virtual objects represented by JSON (see `#schema` below):
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
