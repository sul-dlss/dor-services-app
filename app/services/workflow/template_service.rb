# frozen_string_literal: true

module Workflow
  # Service for interacting with workflow templates.
  class TemplateService
    def self.templates
      new.templates
    end

    def self.template(...)
      new.template(...)
    end

    # @return [Array<String>] a list of all workflow template names
    def templates
      @templates ||= begin
        files = Dir.glob("#{Workflow::TemplateLoader::WORKFLOWS_DIR}/*.xml")
        files.filter_map do |file|
          name = file.sub(%r{#{Workflow::TemplateLoader::WORKFLOWS_DIR}/([^/]*).xml}, '\1')
          name if Settings.skip_workflows.exclude?(name)
        end.sort
      end
    end

    # @param [String] workflow_name the name of the workflow to get the template for
    # @return [Hash] the workflow template
    # @raise [Workflow::Service::NotFoundException] if the template is not found
    def template(workflow_name:)
      loader = Workflow::TemplateLoader.new(workflow_name)
      unless loader.exists?
        raise Workflow::Service::NotFoundException,
              "Workflow template '#{workflow_name}' not found"
      end

      template = loader.load_as_xml
      parser = Workflow::TemplateParser.new(template)
      { 'processes' => parser.processes.map { |process| { 'label' => process.label, 'name' => process.name } } }
    end
  end
end
