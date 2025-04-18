# frozen_string_literal: true

# Service for interacting with workflows.
class WorkflowService
  def self.create(druid:, workflow_name:, version:, context: nil, lane_id: nil)
    new(druid:).create(workflow_name:, version:, context:, lane_id:)
  end

  def self.delete(druid:, workflow_name:, version:)
    new(druid:).delete(workflow_name:, version:)
  end

  def self.delete_all(druid:)
    new(druid:).delete_all
  end

  def self.workflow?(druid:, workflow_name:)
    new(druid:).workflow?(workflow_name:)
  end

  def initialize(druid:)
    @druid = druid
  end

  # @param [String] workflow_name the name of the workflow to check
  # @return [boolean] returns true if the object has the workflow for any version
  def workflow?(workflow_name:)
    workflow_client.all_workflows(pid: druid).workflows.any? { |workflow| workflow.workflow_name == workflow_name }
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
