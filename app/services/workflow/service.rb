# frozen_string_literal: true

module Workflow
  # Service for interacting with workflows.
  class Service
    # Exception class for Workflow::Service.
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
    # @return [Array<Workflow::WorkflowResponse>]
    def workflows
      @workflows ||= workflow_steps_by_workflow.map do |workflow_name, steps|
        Workflow::WorkflowResponse.new(druid:, workflow_name:, steps:)
      end
    end

    # Returns all workflows for the object as XML.
    # Note: The API still uses XML to represent workflows. (Dor::Services::Response::Workflow)
    # Internally, DSA uses Workflow::WorkflowResponse.
    # @return [Nokogiri::XML::Document]
    def workflows_xml
      @workflows_xml ||= Nokogiri::XML::Builder.new do |builder|
        builder.workflows(objectId: druid) do
          workflow_steps_by_workflow.each do |workflow_name, steps|
            build_workflow(builder:, workflow_name:, steps:)
          end
        end
      end.doc
    end

    # @param [String] workflow_name the name of the workflow to check
    # @return [boolean] returns true if the object has the workflow for any version
    def workflow?(workflow_name:)
      workflow(workflow_name:).present?
    end

    # @param [String] workflow_name the name of the workflow to check
    # @return [Dor::Services::Response::Workflow]
    def workflow(workflow_name:)
      steps = WorkflowStep.where(
        druid:,
        workflow: workflow_name
      ).left_outer_joins(:version_context).order(:workflow, created_at: :asc)
      xml = Nokogiri::XML::Builder.new do |builder|
        build_workflow(builder:, workflow_name:, steps:)
      end.to_xml
      Dor::Services::Response::Workflow.new(xml:)
    end

    # @param [String] workflow_name the name of the workflow to create
    # @param [String] version the version of the workflow to create
    # @param [Hash] context
    # @param [String] lane_id
    def create(workflow_name:, version:, context: nil, lane_id: nil)
      template = Workflow::TemplateLoader.load_as_xml(workflow_name)
      raise Workflow::Service::Exception, 'Unknown workflow' if template.nil?

      initial_workflow = Workflow::Transformer.initial_workflow(template, lane_id)
      initial_parser = Workflow::InitialParser.new(initial_workflow)

      Workflow::Creator.new(
        workflow_id: initial_parser.workflow_id,
        processes: initial_parser.processes,
        version: Version.new(
          druid:,
          version:,
          context:
        )
      ).create_workflow_steps
    end

    # Deletes a single workflow.
    # @param [String] workflow_name the name of the workflow to delete
    # @param [String] version the version of the workflow to delete
    def delete(workflow_name:, version:)
      version_obj = Version.new(
        druid:,
        version:
      )
      version_obj.workflow_steps(workflow_name).destroy_all
    end

    # Deletes all workflows for the object.
    def delete_all
      WorkflowStep.where(druid:).destroy_all
    end

    # Skips all processes in a workflow.
    # @param [String] workflow_name the name of the workflow to skip
    # @param [String] note an optional note to add to the skip action
    def skip_all(workflow_name:, note: nil)
      steps = WorkflowStep.where(druid:, active_version: true, workflow: workflow_name)
      WorkflowStep.transaction do
        steps.each do |step|
          step.update(status: 'skipped', note:)
        end
      end
    end

    private

    attr_reader :druid

    def build_workflow(builder:, workflow_name:, steps:)
      builder.workflow(id: workflow_name, objectId: druid) do
        steps.each do |step|
          builder.process(**step.attributes_for_process)
        end
      end
    end

    def workflow_steps_by_workflow
      WorkflowStep.where(druid:)
                  .order(:workflow, created_at: :asc)
                  .group_by(&:workflow)
    end
  end
end
