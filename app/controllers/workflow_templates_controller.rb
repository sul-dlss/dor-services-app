# frozen_string_literal: true

# Controller for workflow templates
class WorkflowTemplatesController < WorkflowApplicationController
  def index
    render json: WorkflowTemplateService.templates
  end

  def show
    render json: WorkflowTemplateService.template(workflow_name: params[:id])
  end
end
