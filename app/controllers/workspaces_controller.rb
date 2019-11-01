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
    head :no_content
  rescue Errno::ENOENT, Errno::ENOTEMPTY => e
    render build_error('Unable to remove directory', e)
  end

  # Once an object has been transferred to preservation, reset the workspace by
  # renaming the druid-tree to a versioned directory
  def reset
    ResetWorkspaceService.reset(druid: params[:object_id], version: @item.current_version)
    head :no_content
  rescue ResetWorkspaceService::DirectoryAlreadyExists => e
    render build_error('Archive directory already exists', e)
  rescue ResetWorkspaceService::BagAlreadyExists => e
    render build_error('Archive bag already exists', e)
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
