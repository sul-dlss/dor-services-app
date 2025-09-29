# frozen_string_literal: true

module Workflow
  # Service for interacting with workflow lifecycles in batches.
  class LifecycleBatchService
    def self.milestones_map(...)
      new(...).milestones_map
    end

    # @param [Array<String>] druids object ids
    def initialize(druids:)
      @druids = druids
    end

    # @return [Hash<String, Array<Hash>>] a map of druid to an array of milestone hashes
    def milestones_map
      steps = WorkflowStep.where(druid: druids).lifecycle.complete

      steps.each_with_object({}) do |step, acc|
        acc[step.druid] ||= []
        acc[step.druid] << { milestone: step.lifecycle, at: step.completed_at || step.created_at,
                             version: step.version.to_s }
      end
    end

    private

    attr_reader :druids
  end
end
