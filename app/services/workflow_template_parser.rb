# frozen_string_literal: true

##
# Parsing workflow template
class WorkflowTemplateParser
  attr_reader :workflow_doc

  Process = Struct.new(:name, :label, :prerequisites, :skip_queue, keyword_init: true)

  # @param [Nokogiri::XML::Document] Workflow template as XML
  def initialize(workflow_doc)
    @workflow_doc = workflow_doc
  end

  def processes
    workflow.xpath('process').map { |process_node| build_process(process_node) }
  end

  private

  def build_process(process_node)
    Process.new(
      name: process_node['name'],
      label: process_node.xpath('label').text,
      prerequisites: process_node.xpath('prereq').map(&:text),
      skip_queue: ActiveModel::Type::Boolean.new.cast(process_node['skip-queue'])
    )
  end

  def workflow
    workflow_doc.xpath('//workflow-def')
  end
end
