# frozen_string_literal: true

# Controller for workflow lifecycles
class WorkflowsController < WorkflowApplicationController
  def index
    render xml: workflow_client.all_workflows(pid: params[:object_id]).xml
  end

  def show
    render xml: workflow_client.workflow(pid: params[:object_id], workflow_name: params[:workflow]).xml
  end
end
