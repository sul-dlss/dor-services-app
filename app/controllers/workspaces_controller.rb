# frozen_string_literal: true

# Handles API routes for managing the DOR workspace
class WorkspacesController < ApplicationController
  before_action :load_item, only: [:create, :reset]

  rescue_from(DruidTools::SameContentExistsError, DruidTools::DifferentContentExistsError) do |e|
    render status: :conflict, plain: e.message
  end

  # POST /v1/objects/:druid/workspace
  def create
    WorkspaceService.create(@item, params[:source])
    head :created
  end

  def destroy
    druid = params[:object_id]
    # decide whether the druid is full or truncated
    if full_druid_tree?(druid)
      CleanupResetService.cleanup_by_reset_druid druid
    else
      CleanupService.cleanup_by_druid druid
    end
    EventFactory.create(druid: druid,
                        event_type: 'cleanup-workspace',
                        data: { status: 'success', full_druid_tree: full_druid_tree?(druid) })

    head :no_content
  rescue Errno::ENOENT, Errno::ENOTEMPTY => e
    EventFactory.create(druid: druid, event_type: 'cleanup-workspace',
                        data: { status: 'failure', full_druid_tree: full_druid_tree?(druid),
                                message: e.message, backtrace: e.backtrace })

    render build_error('Unable to remove directory', e)
  end

  # Once an object has been transferred to preservation, reset the workspace by
  # renaming the druid-tree to a versioned directory.
  def reset
    ResetWorkspaceService.reset(druid: params[:object_id], version: @item.current_version)
    head :no_content
  rescue ResetWorkspaceService::DirectoryAlreadyExists, ResetWorkspaceService::BagAlreadyExists
    # We're trapping errors and doing nothing, because the belief is that these indicate
    # this API has already been called and completed.
    head :no_content
  end

  private

  # determines if the druid is the regular druid tree or the truncated one
  def full_druid_tree?(druid)
    workspace_root = Settings.cleanup.local_workspace_root
    full_druid_tree = DruidTools::Druid.new(druid, workspace_root)
    truncate_druid_tree = DruidTools::AccessDruid.new(druid, workspace_root)
    (!Dir.glob(truncate_druid_tree.path).empty? && !Dir.glob(full_druid_tree.path + '*').empty?)
  end

  # JSON-API error response
  def build_error(msg, err)
    {
      json: {
        errors: [
          {
            "status": '422',
            "title": msg,
            "detail": err.message
          }
        ]
      },
      content_type: 'application/vnd.api+json',
      status: :unprocessable_entity
    }
  end
end
