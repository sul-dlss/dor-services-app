# frozen_string_literal: true

# Transforms workflows.
class WorkflowTransformer
  # Transforms workflow template XML to the xml used to create workflows.
  # @param [Nokogiri::XML::Document] workflow template as XML
  # @param [String] lane_id optional lane id to be set for each processing node
  # @return [Nokogiri::XML::Document] An object's initial workflow as defined by the <workflow-def> in content as XML
  def self.initial_workflow(workflow_template, lane_id = nil)
    WorkflowTransformer.new(workflow_template, lane_id).initial_workflow
  end

  # @param [Nokogiri::XML::Document] workflow template as XML
  # @param [String] lane_id optional lane id to be set for each processing node
  def initialize(workflow_template, lane_id = nil)
    @workflow_template = workflow_template
    @lane_id = lane_id
  end

  # Transforms workflow template XML to the xml used to create workflows.
  # @return [String] An object's initial workflow as defined by the <workflow-def> in content
  def initial_workflow
    doc = Nokogiri::XML('<workflow/>')
    root = doc.root
    root['id'] = name
    workflow_template.xpath('/workflow-def/process').each do |source_process_node|
      doc.create_element 'process' do |node|
        populate_process_node(node, source_process_node)
        root.add_child node
      end
    end
    add_lane_id(doc) unless lane_id.nil?
    doc
  end

  attr_reader :workflow_template, :lane_id

  private

  def populate_process_node(node, source_process_node)
    node['name'] = source_process_node['name']
    if source_process_node['status']
      node['status'] = source_process_node['status']
      node['attempts'] = '1'
    else
      node['status'] = 'waiting'
    end
    node['lifecycle'] = source_process_node['lifecycle'] if source_process_node['lifecycle']
  end

  def name
    workflow_template.at_xpath('/workflow-def/@id').to_s
  end

  def add_lane_id(doc)
    doc.xpath('/workflow/process').each { |proc| proc['laneId'] = lane_id }
  end
end
