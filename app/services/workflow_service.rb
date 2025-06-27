# frozen_string_literal: true

# Service for interacting with workflows.
class WorkflowService
  # Exception class for WorkflowService.
  class Exception < StandardError
    def initialize(message = nil, status: 500)
      super(message)
      @status = status
    end

    attr_reader :status
  end

  # Exception raised when the requested object is not found.
  class NotFoundException < Exception
    def initialize(message = nil)
      super(message || 'Object not found', status: 404)
    end
  end

  def self.create(druid:, workflow_name:, version:, context: nil, lane_id: nil)
    new(druid:).create(workflow_name:, version:, context:, lane_id:)
  end

  def self.delete(druid:, workflow_name:, version:)
    new(druid:).delete(workflow_name:, version:)
  end

  def self.delete_all(druid:)
    new(druid:).delete_all
  end

  def self.workflow(druid:, workflow_name:)
    new(druid:).workflow(workflow_name:)
  end

  def self.workflow?(druid:, workflow_name:)
    new(druid:).workflow?(workflow_name:)
  end

  def self.workflows(...)
    new(...).workflows
  end

  def self.workflows_xml(...)
    new(...).workflows_xml
  end

  def initialize(druid:)
    @druid = druid
  end

  # Returns all workflows for the object.
  # @return [Array<Dor::Workflow::Response::Workflow>]
  # @raise [WorkflowService::NotFoundException] if the object is not found
  def workflows
    @workflows ||= workflow_client.all_workflows(pid: druid).workflows
  end

  # Returns all workflows for the object as XML.
  # @return [Nokogiri::XML::Document]
  # @raise [WorkflowService::NotFoundException] if the object is not found
  def workflows_xml
    @workflows_xml ||= workflow_client.all_workflows(pid: druid).xml
  end

  # @param [String] workflow_name the name of the workflow to check
  # @return [boolean] returns true if the object has the workflow for any version
  # @raise [WorkflowService::NotFoundException] if the object is not found
  def workflow?(workflow_name:)
    workflow(workflow_name:).present?
  end

  # @param [String] workflow_name the name of the workflow to check
  # @return [Dor::Workflow::Response::Workflow,nil]
  # @raise [WorkflowService::NotFoundException] if the object is not found
  def workflow(workflow_name:)
    workflows.find { |workflow| workflow.workflow_name == workflow_name }
  end

  # @param [String] workflow_name the name of the workflow to create
  # @param [String] version the version of the workflow to create
  # @param [Hash] context
  # @param [String] lane_id
  def create(workflow_name:, version:, context: nil, lane_id: nil)
    workflow_client.create_workflow_by_name(druid, workflow_name, version:, context:, lane_id:)
  end

  # Deletes a single workflow.
  # @param [String] workflow_name the name of the workflow to create
  # @param [String] version the version of the workflow to create
  def delete(workflow_name:, version:)
    workflow_client.delete_workflow(druid:, workflow: workflow_name, version:)
  end

  # Deletes all workflows for the object.
  # @param [String] druid the druid of the object
  def delete_all
    workflow_client.delete_all_workflows(pid: druid)
  end

  private

  attr_reader :druid

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
