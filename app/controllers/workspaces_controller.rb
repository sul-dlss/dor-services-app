# frozen_string_literal: true

# Handles API routes for managing the DOR workspace
class WorkspacesController < ApplicationController
  before_action :load_item

  rescue_from(DruidTools::SameContentExistsError, DruidTools::DifferentContentExistsError) do |e|
    render status: 409, plain: e.message
  end

  # POST /v1/objects/:druid/workspace
  # and the deprecated:
  # POST /v1/objects/:druid/initialize_workspace
  def create
    WorkspaceService.create(@item, params[:source])
    head :created
  end
end
