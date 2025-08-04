# frozen_string_literal: true

module Workflow
  # Parsing Workflow XML
  class Creator
    attr_reader :version

    ##
    # @param [Array<ProcessParser>] processes
    # @param [String] workflow_id the workflow identifier
    # @param [Version] version the object/version
    def initialize(processes:, workflow_id:, version:)
      @processes = processes
      @workflow_id = workflow_id
      @version = version
    end

    ##
    # Delete all the rows for this druid/version/workflow, and replace with new rows.
    # @return [Array]
    # rubocop:disable Metrics/AbcSize
    def create_workflow_steps
      ActiveRecord::Base.transaction do
        version.workflow_steps(workflow_id).destroy_all

        # Any steps for this object/workflow that are not the current version are marked as not active.
        WorkflowStep.where(workflow: workflow_id, druid: version.druid).update(active_version: false)

        processes.map do |process|
          WorkflowStep.create!(workflow_attributes(process))
        end

        # Create/update version context
        version.update_context
      end
      enqueue
    end
    # rubocop:enable Metrics/AbcSize

    private

    attr_reader :processes, :workflow_id

    def enqueue
      # Get the first step and enqueue any next steps
      first_step = WorkflowStep.find_by(workflow: workflow_id, druid: version.druid, active_version: true,
                                        process: processes.first.process)

      # Enqueue next steps
      Workflow::NextStepService.enqueue_next_steps(step: first_step)
    end

    def workflow_attributes(process)
      {
        workflow: workflow_id,
        druid: version.druid,
        process: process.process,
        status: process.status,
        lane_id: process.lane_id,
        lifecycle: process.lifecycle,
        version: version.version_id,
        active_version: true
      }
    end
  end
end
