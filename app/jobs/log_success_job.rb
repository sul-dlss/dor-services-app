# frozen_string_literal: true

# Update the BackgroundJobResult and alert the workflow service
# This is done as a separate job so that if the work is complete, but there is an
# error writing this data, we don't have to re-do the work.
class LogSuccessJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  # @param [String,NilClass] workflow If provided, which workflow should this be reported to
  # @param [String] workflow_process
  def perform(druid:, background_job_result:, workflow:, workflow_process:)
    background_job_result.complete!

    return unless workflow

    WorkflowClientFactory.build.update_status(druid:,
                                              workflow:,
                                              process: workflow_process,
                                              status: 'completed',
                                              elapsed: 1,
                                              note: "Completed Job #{background_job_result.id} on dor-services-app")
  end
end
