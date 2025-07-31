# frozen_string_literal: true

# Controller for workflow templates
class WorkflowTemplatesController < WorkflowApplicationController
  def index
    render json: Workflow::TemplateService.templates
  end

  def show
    render json: Workflow::TemplateService.template(workflow_name: params[:id])
  end
end
