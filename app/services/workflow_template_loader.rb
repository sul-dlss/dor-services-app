# frozen_string_literal: true

##
# Loading workflow templates
class WorkflowTemplateLoader
  WORKFLOWS_DIR = 'config/workflows'
  # Loads a workflow template from file
  # @param [String] workflow_name name/id of workflow, e.g., accessionWF
  # @return [String or nil] the workflow as a string or nil if not found
  def self.load(workflow_name)
    WorkflowTemplateLoader.new(workflow_name).load
  end

  # Loads a workflow template from file as XML
  # @param [String] workflow_name name/id of workflow, e.g., accessionWF
  # @return [Nokogiri::XML::Document or nil] the workflow as XML or nil if not found
  def self.load_as_xml(workflow_name)
    WorkflowTemplateLoader.new(workflow_name).load_as_xml
  end

  # @param [String] workflow_name name/id of workflow, e.g., accessionWF
  def initialize(workflow_name)
    @workflow_name = workflow_name
  end

  # @return [String or nil] the filepath of the workflow file or nil if not found
  def workflow_filepath
    @workflow_filepath ||= "#{WORKFLOWS_DIR}/#{workflow_name}.xml"
  end

  # @return [boolean] true if the workflow file is found
  def exists?
    File.exist?(workflow_filepath)
  end

  # @return [String or nil] contents of the workflow file or nil if not found
  def load
    exists? ? File.read(workflow_filepath) : nil
  end

  # @return [Nokogiri::XML::Document or nil] contents of the workflow file as XML or nil if not found
  def load_as_xml
    exists? ? Nokogiri::XML(load) : nil
  end

  attr_reader :workflow_name
end
