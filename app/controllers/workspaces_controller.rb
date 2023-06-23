# frozen_string_literal: true

# Handles API routes for managing the DOR workspace
class WorkspacesController < ApplicationController
  before_action :load_cocina_object, only: [:create, :reset]

  rescue_from(DruidTools::SameContentExistsError, DruidTools::DifferentContentExistsError) do |e|
    render status: :conflict, plain: e.message
  end

  # POST /v1/objects/:druid/workspace
  def create
    WorkspaceService.create(@cocina_object, params[:source])
    head :created
  end

  def destroy
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:object_id], event_type: 'cleanup_request_received', data: { background_job_result_id: result.id })
    CleanupJob.set(queue: params['lane-id']).perform_later(druid: params[:object_id], background_job_result: result, workflow: params[:workflow])
    head :created, location: result
  end

  # Once an object has been transferred to preservation, reset the workspace by
  # renaming the druid-tree to a versioned directory and removing the export directory
  def reset
    ResetWorkspaceJob.perform_later(druid: params[:object_id], version: @cocina_object.version)
    head :no_content
  end

  private

  # JSON-API error response
  def build_error(msg, err)
    {
      json: {
        errors: [
          {
            status: '422',
            title: msg,
            detail: err.message
          }
        ]
      },
      content_type: 'application/vnd.api+json',
      status: :unprocessable_entity
    }
  end
end
