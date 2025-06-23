# frozen_string_literal: true

# Controller for workflow lifecycles
class WorkflowLifecyclesController < ApplicationController
  def index
    render xml: workflow_client.query_lifecycle(druid: params[:object_id], version: params[:version],
                                                active_only: params[:active_only] == 'true')
  end

  private

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
