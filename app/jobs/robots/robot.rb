# frozen_string_literal: true

module Robots
  # Base class for DSA robots.
  class Robot < LyberCore::Robot
    def cocina_object
      @cocina_object ||= CocinaObjectStore.find(druid)
    end

    def object_client
      raise '.object_client should not be used from a DSA robot'
    end

    private

    def workflow
      @workflow ||= RobotWorkflow.new(workflow_name: workflow_name, process: process, druid:)
    end

    # This encapsulates the workflow operations that lyber-core does.
    # This implementation uses local services instead of the dor-services-client.
    # It should have the same interface as LyberCore::Workflow.
    class RobotWorkflow
      def initialize(workflow_name:, process:, druid:)
        @workflow_name = workflow_name
        @process = process
        @druid = druid
      end

      def object_workflow
        raise '.object_workflow should not be used from a DSA robot'
      end

      def workflow_process
        raise '.workflow_process should not be used from a DSA robot'
      end

      # @return [Dor::Services::Response::Workflow] for druid/workflow/step on which this instance was initialized
      def workflow_response
        @workflow_response ||= Workflow::Service.workflow(druid:, workflow_name: workflow_name)
      end

      # @return [Dor::Services::Response::Process] for druid/workflow/step on which this instance was initialized
      def process_response
        @process_response ||= workflow_response.process_for_recent_version(name: process)
      end

      def start!(note)
        Workflow::ProcessService.update(druid:, workflow_name:, process:, status: 'started', note:, elapsed: 1.0)
      end

      def complete!(status, elapsed, note)
        Workflow::ProcessService.update(druid:, workflow_name:, process:, status:, note:, elapsed:)
      end

      def retrying!
        Workflow::ProcessService.update(druid:, workflow_name:, process:, status: 'retrying', note: nil, elapsed: 1.0)
      end

      def error!(error_msg, error_text)
        Workflow::ProcessService.update_error(druid:, workflow_name:, process:, error_msg:, error_text:)
      end

      delegate :context, :status, :lane_id, to: :process_response

      attr_reader :workflow_name, :process, :druid
    end
  end
end
