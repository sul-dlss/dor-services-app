# frozen_string_literal: true

# Controller for workflow lifecycles
class WorkflowLifecyclesController < WorkflowApplicationController
  def index
    render xml: Workflow::LifecycleService.lifecycle_xml(druid: params[:object_id], version: params[:version]&.to_i)
  end
end
