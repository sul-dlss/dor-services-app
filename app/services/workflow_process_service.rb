# frozen_string_literal: true

# Service for interacting with workflows processes (steps).
class WorkflowProcessService
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
  # @param [String] lifecycle Bookeeping label for this particular workflow step.  Examples are: 'registered', 'shelved'
  # @param [String] note Any kind of string annotation that you want to attach to the workflow
  # @param [String] current_status Compare the current status to this value and raise if mismatch.
  # @raise [WorkflowService::ConflictException] if the current status does not match the value passed in current_status.
  # @raise [WorkflowService::NotFoundException] if the workflow step is not found.
  def update(status:, elapsed: 0, lifecycle: nil, note: nil, # rubocop:disable Metrics/AbcSize
             current_status: nil)
    workflow_client.update_status(druid:, workflow: workflow_name, process:, status:, elapsed:,
                                  lifecycle:, note:, current_status:)
  rescue Dor::MissingWorkflowException
    raise WorkflowService::NotFoundException, "Process #{process} not found in #{workflow_name} for #{druid}"
  rescue Dor::WorkflowException => e
    raise WorkflowService::Exception, e unless e.message.include?('HTTP status 409')

    raise WorkflowService::ConflictException,
          "Process #{process} in workflow #{workflow_name} for #{druid} has a conflict: #{e.message}"
  end

  # Updates the status of one step in a workflow to error.
  # @param [String] error_msg The error message.  Ideally, this is a brief message describing the error
  # @param [String] error_text A slot to hold more information about the error, like a full stacktrace
  def update_error(error_msg:, error_text: nil)
    workflow_client.update_error_status(druid:, workflow: workflow_name, process:, error_msg:, error_text:)
  rescue Dor::MissingWorkflowException
    raise WorkflowService::NotFoundException, "Process #{process} not found in #{workflow_name} for #{druid}"
  end

  private

  attr_reader :druid, :workflow_name, :process

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
