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

  # Exception raised when there is a conflict in the workflow state.
  class ConflictException < Exception
    def initialize(message = nil)
      super(message || 'Conflict occurred', status: 409)
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

  def self.skip_all(druid:, workflow_name:, note: nil)
    new(druid:).skip_all(workflow_name:, note:)
  end

  def initialize(druid:)
    @druid = druid
  end

  # Returns all workflows for the object.
  # @return [Array<Dor::Services::Response::Workflow>]
  def workflows
    @workflows ||= if Settings.enabled_features.local_wf
                     Dor::Services::Response::Workflows.new(xml: workflows_xml).workflows
                   else
                     workflow_client.all_workflows(pid: druid).workflows
                   end
  end

  # Returns all workflows for the object as XML.
  # @return [Nokogiri::XML::Document]
  def workflows_xml # rubocop:disable Metrics/AbcSize
    @workflows_xml ||= if Settings.enabled_features.local_wf
                         workflow_steps = WorkflowStep.where(druid:)
                                                      .order(:workflow, created_at: :asc)
                                                      .group_by(&:workflow)
                         xml = Nokogiri::XML::Builder.new do |builder|
                           builder.workflows(objectId: druid) do
                             workflow_steps.each do |workflow_name, steps|
                               build_workflow(builder:, workflow_name:, steps:)
                             end
                           end
                         end.to_xml
                         Nokogiri::XML(xml)
                       else
                         workflow_client.all_workflows(pid: druid).xml
                       end
  end

  # @param [String] workflow_name the name of the workflow to check
  # @return [boolean] returns true if the object has the workflow for any version
  def workflow?(workflow_name:)
    workflow(workflow_name:).present?
  end

  # @param [String] workflow_name the name of the workflow to check
  # @return [Dor::Workflow::Response::Workflow]
  def workflow(workflow_name:)
    if Settings.enabled_features.local_wf
      steps = WorkflowStep.where(
        druid:,
        workflow: workflow_name
      ).left_outer_joins(:version_context).order(:workflow, created_at: :asc)
      xml = Nokogiri::XML::Builder.new do |builder|
        build_workflow(builder:, workflow_name:, steps:)
      end.to_xml
      Dor::Services::Response::Workflow.new(xml:)
    else
      workflow_client.workflow(pid: druid, workflow_name:)
    end
  end

  # @param [String] workflow_name the name of the workflow to create
  # @param [String] version the version of the workflow to create
  # @param [Hash] context
  # @param [String] lane_id
  def create(workflow_name:, version:, context: nil, lane_id: nil)
    if Settings.enabled_features.local_wf
      template = WorkflowTemplateLoader.load_as_xml(workflow_name)
      raise WorkflowService::Exception, 'Unknown workflow' if template.nil?

      initial_workflow = WorkflowTransformer.initial_workflow(template, lane_id)
      initial_parser = InitialWorkflowParser.new(initial_workflow)

      WorkflowCreator.new(
        workflow_id: initial_parser.workflow_id,
        processes: initial_parser.processes,
        version: Version.new(
          druid:,
          version:,
          context:
        )
      ).create_workflow_steps

    else
      workflow_client.create_workflow_by_name(druid, workflow_name, version:, context:, lane_id:)
    end
  end

  # Deletes a single workflow.
  # @param [String] workflow_name the name of the workflow to delete
  # @param [String] version the version of the workflow to delete
  def delete(workflow_name:, version:)
    if Settings.enabled_features.local_wf
      version_obj = Version.new(
        druid:,
        version:
      )
      version_obj.workflow_steps(workflow_name).destroy_all
    else
      workflow_client.delete_workflow(druid:, workflow: workflow_name, version:)
    end
  end

  # Deletes all workflows for the object.
  def delete_all
    if Settings.enabled_features.local_wf
      WorkflowStep.where(druid:).destroy_all
    else
      workflow_client.delete_all_workflows(pid: druid)
    end
  end

  # Skips all processes in a workflow.
  # @param [String] workflow_name the name of the workflow to skip
  # @param [String] note an optional note to add to the skip action
  def skip_all(workflow_name:, note: nil)
    if Settings.enabled_features.local_wf
      steps = WorkflowStep.where(druid:, active_version: true, workflow: workflow_name)
      WorkflowStep.transaction do
        steps.each do |step|
          step.update(status: 'skipped', note:)
        end
      end
    else
      workflow_client.skip_all(druid:, workflow: workflow_name, note:)
    end
  end

  private

  attr_reader :druid

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end

  def build_workflow(builder:, workflow_name:, steps:)
    builder.workflow(id: workflow_name, objectId: druid) do
      steps.each do |step|
        builder.process(**step.attributes_for_process)
      end
    end
  end
end
