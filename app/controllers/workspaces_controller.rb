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
    druid = params[:object_id]
    CleanupService.cleanup_by_druid druid

    EventFactory.create(druid: druid,
                        event_type: 'cleanup-workspace',
                        data: { status: 'success' })

    head :no_content
  rescue Errno::ENOENT, Errno::ENOTEMPTY => e
    EventFactory.create(druid: druid, event_type: 'cleanup-workspace',
                        data: { status: 'failure', message: e.message, backtrace: e.backtrace })

    render build_error('Unable to remove directory', e)
  end

  # Once an object has been transferred to preservation, reset the workspace by
  # renaming the druid-tree to a versioned directory.
  def reset
    ResetWorkspaceService.reset(druid: params[:object_id], version: @cocina_object.version)
    head :no_content
  rescue ResetWorkspaceService::DirectoryAlreadyExists, ResetWorkspaceService::BagAlreadyExists
    # We're trapping errors and doing nothing, because the belief is that these indicate
    # this API has already been called and completed.
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
