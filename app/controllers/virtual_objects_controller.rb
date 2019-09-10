# frozen_string_literal: true

# Create virtual objects
class VirtualObjectsController < ApplicationController
  before_action :validate_params!, only: :create

  # Create one or more virtual objects represented by JSON (see `#schema` below):
  def create
    errors = []

    create_params[:virtual_objects].each do |virtual_object|
      parent_id, child_ids = virtual_object.values_at(:parent_id, :child_ids)
      # Update the constituent relationship between the parent and child druids
      errors << ConstituentService.new(parent_druid: parent_id).add(child_druids: child_ids)
    rescue ActiveFedora::ObjectNotFoundError, Rubydora::FedoraInvalidRequest => e
      errors << { parent_id => [e.message] }
    end

    return render_error(errors: errors, status: :unprocessable_entity) if errors.any?

    head :no_content
  end

  private

  def create_params
    params.to_unsafe_h
  end

  # Use dry-validation to validate params instead of Rails strong parameters.
  # This gives us finer-grained validation.
  def validate_params!
    errors = schema.call(create_params).errors(full: true)
    return render_error(errors: errors, status: :bad_request) if errors.any?
  end

  def render_error(errors:, status:)
    render json: { errors: errors }, status: status
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
