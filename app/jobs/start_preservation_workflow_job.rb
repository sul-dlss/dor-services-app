# frozen_string_literal: true

# Update the BackgroundJobResult and alert the workflow service
# This is done as a separate job so that if the work is complete, but there is an
# error writing this data, we don't have to re-do the work.
class StartPreservationWorkflowJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    # start SDR preservation workflow
    Dor::Config.workflow.client.create_workflow_by_name(druid, 'preservationIngestWF')

    LogSuccessJob.perform_later(druid: druid,
                                workflow: 'accessionWF',
                                background_job_result: background_job_result,
                                workflow_process: 'preservation-ingest-initiated')
  end
end
