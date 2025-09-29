# frozen_string_literal: true

module Workflow
  # Adapts a WorkflowStep to a Dor::Services::Response::Process
  class ProcessResponse
    def initialize(step:)
      @step = step
    end

    delegate :status, :elapsed, :attempts, :lifecycle, :note, :lane_id, :context, to: :step

    def name
      step.process
    end

    def datetime
      step.updated_at.to_time.iso8601
    end

    def error_message
      step.error_msg
    end

    def workflow_name
      step.workflow
    end

    def pid
      step.druid
    end

    private

    attr_reader :step
  end
end
