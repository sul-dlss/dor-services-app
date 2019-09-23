# frozen_string_literal: true

# Handles API routes for managing the DOR workspace
class WorkspacesController < ApplicationController
  rescue_from(DruidTools::SameContentExistsError, DruidTools::DifferentContentExistsError) do |e|
    render status: :conflict, plain: e.message
  end

  # POST /v1/objects/:druid/workspace
  def create
    WorkspaceService.create(load_item, params[:source])
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
  end

  # Once an object has been transfered to preservation clean up the workspace.
  def reset
    druid_obj = Dor.find(params[:object_id])
    ResetWorkspaceService.reset(druid: params[:object_id], version: druid_obj.current_version)
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
end
