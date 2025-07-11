# frozen_string_literal: true

# Service for interacting with workflow templates.
class WorkflowTemplateService
  def self.templates
    new.templates
  end

  def self.template(...)
    new.template(...)
  end

  # @return [Array<String>] a list of all workflow template names
  def templates
    @templates ||= workflow_client.workflow_templates
  end

  # @param [String] workflow_name the name of the workflow to get the template for
  # @return [Hash] the workflow template
  # @raise [WorkflowService::NotFoundException] if the template is not found
  def template(workflow_name:)
    workflow_client.workflow_template(workflow_name)
  rescue Dor::MissingWorkflowException
    raise WorkflowService::NotFoundException, "Workflow template '#{workflow_name}' not found"
  end

  private

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
