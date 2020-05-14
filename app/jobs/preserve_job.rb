# frozen_string_literal: true

# Move an object to Preservation (SDR) in the background
class PreserveJob < ApplicationJob
  queue_as :default

  retry_on StandardError do |job, error|
    opts = job.arguments.first
    Honeybadger.context(background_job_result_id: opts[:background_job_result].id)
    LogFailureJob.perform_later(druid: opts[:druid],
                                background_job_result: opts[:background_job_result],
                                workflow: 'accessionWF',
                                workflow_process: 'sdr-ingest-transfer',
                                output: { errors: [{ title: 'Preservation error', detail: error.message }] })
  end

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    background_job_result.processing!

    item = Dor.find(druid)
    SdrIngestService.transfer(item) # This might raise a StandardError which will be handled by the retry above.

    StartPreservationWorkflowJob.perform_later(druid: druid,
                                               version: item.current_version,
                                               background_job_result: background_job_result)
  end
end
