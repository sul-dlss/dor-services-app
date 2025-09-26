# frozen_string_literal: true

module Workflow
  # Service for retrieving the workflows of a batch of objects.
  class BatchService
    def self.workflows(...)
      new(...).workflows
    end

    def initialize(druids:)
      @druids = druids
    end

    # @return [Hash<String, Array<Dor::Services::Response::Workflow>>] mapping of druid to array of workflows
    def workflows
      steps_by_druid = WorkflowStep.where(druid: druids).order(:druid, :workflow, created_at: :asc).group_by(&:druid)
      steps_by_druid.each_with_object({}) do |(druid, steps), hash|
        hash[druid] = build_workflows(druid:, steps:)
      end
    end

    private

    attr_reader :druids

    def build_workflows(druid:, steps:)
      steps_by_workflow = steps.group_by(&:workflow)
      xml = Nokogiri::XML::Builder.new do |builder|
        builder.workflows(objectId: druid) do
          steps_by_workflow.each do |workflow_name, steps|
            build_workflow(builder:, workflow_name:, steps:, druid:)
          end
        end
      end.to_xml
      Dor::Services::Response::Workflows.new(xml: Nokogiri::XML(xml)).workflows
    end

    def build_workflow(builder:, workflow_name:, steps:, druid:)
      builder.workflow(id: workflow_name, objectId: druid) do
        steps.each do |step|
          builder.process(**step.attributes_for_process)
        end
      end
    end
  end
end
