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
      steps_by_workflow.map do |workflow_name, steps|
        Workflow::WorkflowResponse.new(druid:, workflow_name:, steps:)
      end
    end
  end
end
