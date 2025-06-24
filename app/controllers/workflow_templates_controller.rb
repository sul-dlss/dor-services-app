# frozen_string_literal: true

# Controller for workflow templates
class WorkflowTemplatesController < WorkflowApplicationController
  def index
    render json: workflow_client.workflow_templates
  end
end
