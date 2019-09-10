# frozen_string_literal: true

# Create virtual objects
class VirtualObjectsController < ApplicationController
  # Create one or more virtual objects represented by JSON:
  # {
  #   virtual_objects: [
  #     { parent_id: '', child_ids: [] }
  #   ]
  # }
  def create
    # validate that the virtual_objects parameter is an present, raises ActionController::ParameterMissing
    params.require(:virtual_objects)
    filtered_params = params.permit(virtual_objects: [:parent_id, child_ids: []])
    raise ActionController::ParameterMissing, 'virtual_objects must be an array' unless filtered_params[:virtual_objects]

    errors = []

    filtered_params[:virtual_objects].each do |virtual_object|
      # Update the constituent relationship between the parent and child druids
      errors << ConstituentService.new(parent_druid: virtual_object[:parent_id]).add(child_druids: virtual_object[:child_ids])
    end

    return render json: { errors: errors }, status: :unprocessable_entity if errors.any?

    head :no_content
  end
end
