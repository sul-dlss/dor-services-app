# frozen_string_literal: true

# Move an object to SDR in the background
class PreserveJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    background_job_result.processing!

    begin
      item = Dor.find(druid)
      SdrIngestService.transfer(item)
    rescue StandardError => e
      return LogFailureJob.perform_later(druid: druid,
                                         background_job_result: background_job_result,
                                         workflow_process: 'sdr-ingest-transfer',
                                         output: { errors: [{ title: 'Preservation error', detail: e.message }] })
    end

    StartPreservationWorkflowJob.perform_later(druid: druid, background_job_result: background_job_result)
  end
end
