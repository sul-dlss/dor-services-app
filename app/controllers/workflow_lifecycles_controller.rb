# frozen_string_literal: true

# Controller for workflow lifecycles
class WorkflowLifecyclesController < WorkflowApplicationController
  def index
    render xml: Workflow::LifecycleService.lifecycle_xml(druid: params[:object_id], version: params[:version],
                                                         active_only: params[:active_only] == 'true')
  end
end
