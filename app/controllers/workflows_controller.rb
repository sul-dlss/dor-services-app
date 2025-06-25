# frozen_string_literal: true

# Controller for workflow lifecycles
class WorkflowsController < WorkflowApplicationController
  def index
    render xml: workflow_client.all_workflows(pid: params[:object_id]).xml
  end

  def show
    render xml: workflow_client.workflow(pid: params[:object_id], workflow_name: params[:workflow]).xml
  end

  def create
    workflow_client.create_workflow_by_name(params[:object_id], params[:workflow],
                                            version: params[:version],
                                            lane_id: params[:'lane-id'] || 'default',
                                            context: params[:context]&.to_unsafe_hash)

    head :created
  end
end
