# frozen_string_literal: true

# Controller for workflow lifecycles
class WorkflowsController < WorkflowApplicationController
  def index
    render xml: Workflow::Service.workflows_xml(druid:)
  end

  def show
    render xml: Workflow::Service.workflow(druid:, workflow_name:).xml
  end

  def create
    Workflow::Service.create(druid:, workflow_name:,
                             version: params[:version],
                             context: params[:context]&.to_unsafe_hash,
                             lane_id: params[:'lane-id'] || 'default')

    head :created
  end

  def skip_all
    Workflow::Service.skip_all(druid:, workflow_name:, note: params[:note])

    head :no_content
  end

  private

  def druid
    params[:object_id]
  end

  def workflow_name
    params[:id]
  end
end
