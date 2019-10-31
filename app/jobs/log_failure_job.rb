# frozen_string_literal: true

# Update the BackgroundJobResult and alert the workflow service
# This is done as a separate job so that if the work is complete, but there is an
# error writing to the database or workflow service, we don't have to re-do the work.
class LogFailureJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  # @param [String] workflow_process
  # @param [Hash] output
  def perform(druid:, background_job_result:, workflow_process:, output:)
    background_job_result.output = output
    background_job_result.complete!

    Dor::Config.workflow.client.update_error_status(druid: druid,
                                                    workflow: 'accessionWF',
                                                    process: workflow_process,
                                                    error_msg: "problem with #{workflow_process} (BackgroundJob: #{background_job_result.id})",
                                                    error_text: output.inspect)
  end
end
