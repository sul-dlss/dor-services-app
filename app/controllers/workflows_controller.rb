# frozen_string_literal: true

# Controller for workflow lifecycles
class WorkflowsController < WorkflowApplicationController
  def index
    render xml: WorkflowService.workflows_xml(druid:)
  end

  def show
    render xml: workflow_client.workflow(pid: druid, workflow_name: workflow).xml
  end

  def create
    WorkflowService.create(druid:, workflow_name: workflow,
                           version: params[:version],
                           context: params[:context]&.to_unsafe_hash,
                           lane_id: params[:'lane-id'] || 'default')

    head :created
  end

  def skip_all
    workflow_client.skip_all(druid:, workflow:, note: params[:note])

    head :no_content
  end

  private

  def druid
    params[:object_id]
  end

  def workflow
    params[:id]
  end
end
