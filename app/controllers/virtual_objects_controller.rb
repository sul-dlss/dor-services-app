# frozen_string_literal: true

# Create virtual objects
class VirtualObjectsController < ApplicationController
  before_action :validate_params!, only: :create

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

  # Use dry-validation to validate params instead of Rails strong parameters.
  # This gives us finer-grained validation.
  def validate_params!
    errors = schema.call(create_params).errors(full: true)
    return render json: { errors: errors }, status: :bad_request if errors.any?
  end

  # {
  #   virtual_objects: [
  #     {
  #       parent_id: 'a-non-empty-string',
  #       child_ids: [
  #         'another-non-empty-string',
  #         ...
  #       ]
  #     },
  #     ...
  #   ]
  # }
  def schema
    Dry::Schema.JSON do
      required(:virtual_objects).value(:array, min_size?: 1).each do
        hash do
          required(:parent_id).filled(:string)
          required(:child_ids).value(:array, min_size?: 1).each(:filled?)
        end
      end
    end
  end
end
