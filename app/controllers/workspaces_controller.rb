# frozen_string_literal: true

# Handles API routes for managing the DOR workspace
class WorkspacesController < ApplicationController
  rescue_from(DruidPath::SameContentExistsError, DruidPath::DifferentContentExistsError) do |e|
    render status: 409, plain: e.message
  end

  # POST /v1/objects/:druid/workspace
  # and the deprecated:
  # POST /v1/objects/:druid/initialize_workspace
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

  private

  # determines if the druid is the regular druid tree or the truncated one
  def full_druid_tree?(druid)
    workspace_root = Settings.cleanup.local_workspace_root
    full_druid_tree = DruidTools::Druid.new(druid, workspace_root)
    truncate_druid_tree = DruidTools::AccessDruid.new(druid, workspace_root)
    (!Dir.glob(truncate_druid_tree.path).empty? && !Dir.glob(full_druid_tree.path + '*').empty?)
  end
end
