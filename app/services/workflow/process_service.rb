# frozen_string_literal: true

module Workflow
  # Service for interacting with workflows processes (steps).
  class ProcessService
    def self.update(druid:, workflow_name:, process:, status:, elapsed: 0, lifecycle: nil, note: nil, # rubocop:disable Metrics/ParameterLists
                    current_status: nil)
      new(druid:, workflow_name:, process:).update(status:, elapsed:, lifecycle:, note:, current_status:)
    end

    def self.update_error(druid:, workflow_name:, process:, error_msg:, error_text: nil)
      new(druid:, workflow_name:, process:).update_error(error_msg:, error_text:)
    end

    # @param [String] druid
    # @param [String] workflow_name The name of the workflow
    # @param [String] process The name of the workflow step
    def initialize(druid:, workflow_name:, process:)
      @druid = druid
      @workflow_name = workflow_name
      @process = process
    end

    # Updates the status of one step in a workflow.
    # @param [String] status The status of the process.
    # @param [Float] elapsed The number of seconds it took to complete this step. Can have a decimal.
    # @param [String] lifecycle Bookeeping label for this particular workflow step.  Examples: 'registered', 'shelved'
    # @param [String] note Any kind of string annotation that you want to attach to the workflow
    # @param [String] current_status Compare the current status to this value and raise if mismatch.
    # @raise [Workflow::Service::ConflictException] if the current status does not match the passed in current_status.
    # @raise [Workflow::Service::NotFoundException] if the workflow step is not found.
    def update(status:, elapsed: 0, lifecycle: nil, note: nil, # rubocop:disable Metrics/AbcSize
               current_status: nil)
      if Settings.enabled_features.local_wf
        update_status(status:, elapsed:, lifecycle:, note:, current_status:)
      else
        begin
          workflow_client.update_status(druid:, workflow: workflow_name, process:, status:, elapsed:,
                                        lifecycle:, note:, current_status:)
        rescue Dor::MissingWorkflowException
          raise Workflow::Service::NotFoundException, "Process #{process} not found in #{workflow_name} for #{druid}"
        rescue Dor::WorkflowException => e
          raise Workflow::Service::Exception, e unless e.message.include?('HTTP status 409')

          raise Workflow::Service::ConflictException,
                "Process #{process} in workflow #{workflow_name} for #{druid} has a conflict: #{e.message}"
        end
      end
    end

    # Updates the status of one step in a workflow to error.
    # @param [String] error_msg The error message.  Ideally, this is a brief message describing the error
    # @param [String] error_text A slot to hold more information about the error, like a full stacktrace
    def update_error(error_msg:, error_text: nil)
      if Settings.enabled_features.local_wf
        update_status(status: 'error', error_msg:, error_text:)
      else
        begin
          workflow_client.update_error_status(druid:, workflow: workflow_name, process:, error_msg:, error_text:)
        rescue Dor::MissingWorkflowException
          raise Workflow::Service::NotFoundException, "Process #{process} not found in #{workflow_name} for #{druid}"
        end
      end
    end

    private

    attr_reader :druid, :workflow_name, :process

    def workflow_client
      @workflow_client ||= WorkflowClientFactory.build
    end

    def update_status(status:, elapsed: 0, lifecycle: nil, note: nil, # rubocop:disable Metrics/ParameterLists
                      current_status: nil, error_msg: nil, error_text: nil)
      parser = ProcessParser.new(status:, elapsed:, lifecycle:, note:,
                                 error_msg:, error_txt: error_text, use_default_lane_id: false)

      step = find_step_for_process

      check_step_exists!(step)
      check_current_status!(step, current_status)

      # We need this transaction to be committed before we kick off indexing/next steps
      # or they could find the data to be in an outdated state.
      WorkflowStep.transaction do
        step.update(parser.to_h)
      end

      # Enqueue next steps
      NextStepService.enqueue_next_steps(step:)
    end

    def find_step_for_process
      query = WorkflowStep.where(druid:,
                                 workflow: workflow_name,
                                 process: process)
                          .order(version: :desc)
      # Validate uniqueness until https://github.com/sul-dlss/workflow-server-rails/pull/40 is in place
      if query.size != query.pluck(:version).uniq.size
        raise "Duplicate workflow step for #{druid} #{workflow_name} #{process}"
      end

      query.first
    end

    def check_step_exists!(step)
      return unless step.nil?

      raise Workflow::Service::NotFoundException, "Process #{process} not found in #{workflow_name} for #{druid}"
    end

    def check_current_status!(step, current_status)
      return unless current_status.present? && step.status != current_status

      raise Workflow::Service::ConflictException,
            "Process #{process} in workflow #{workflow_name} for #{druid} has a conflict: " \
            "expected status #{current_status}, but found #{step.status}"
    end
  end
end
