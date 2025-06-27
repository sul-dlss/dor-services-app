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
    workflow_client.create_workflow_by_name(druid, workflow,
                                            version: params[:version],
                                            lane_id: params[:'lane-id'] || 'default',
                                            context: params[:context]&.to_unsafe_hash)

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
