# frozen_string_literal: true

# Handles API routes for managing the DOR workspace
class WorkspacesController < ApplicationController
  before_action :check_cocina_object_exists, only: %i[create]

  rescue_from(DruidTools::SameContentExistsError, DruidTools::DifferentContentExistsError) do |e|
    render status: :conflict, plain: e.message
  end

  # POST /v1/objects/:druid/workspace
  def create
    result = WorkspaceService.create(params[:object_id], params[:source], content: ActiveModel::Type::Boolean.new.cast(params[:content]), metadata: ActiveModel::Type::Boolean.new.cast(params[:metadata]))
    render status: :created, json: { path: result }
  end

  def destroy
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:object_id], event_type: 'cleanup_request_received', data: { background_job_result_id: result.id })
    CleanupJob.set(queue: params['lane-id']).perform_later(druid: params[:object_id], background_job_result: result)
    head :created, location: result
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
      status: :unprocessable_content
    }
  end
end
