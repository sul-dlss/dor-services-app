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
    @templates ||= if Settings.enabled_features.local_wf
                     files = Dir.glob("#{WorkflowTemplateLoader::WORKFLOWS_DIR}/*.xml")
                     files.map { |file| file.sub(%r{#{WorkflowTemplateLoader::WORKFLOWS_DIR}/([^/]*).xml}, '\1') }.sort
                   else
                     workflow_client.workflow_templates
                   end
  end

  # @param [String] workflow_name the name of the workflow to get the template for
  # @return [Hash] the workflow template
  # @raise [WorkflowService::NotFoundException] if the template is not found
  def template(workflow_name:)
    if Settings.enabled_features.local_wf
      loader = WorkflowTemplateLoader.new(workflow_name)
      raise WorkflowService::NotFoundException, "Workflow template '#{workflow_name}' not found" unless loader.exists?

      template = loader.load_as_xml
      parser = WorkflowTemplateParser.new(template)
      { 'processes' => parser.processes.map { |process| { 'label' => process.label, 'name' => process.name } } }
    else
      begin
        workflow_client.workflow_template(workflow_name)
      rescue Dor::MissingWorkflowException
        raise WorkflowService::NotFoundException, "Workflow template '#{workflow_name}' not found"
      end
    end
  end

  private

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
