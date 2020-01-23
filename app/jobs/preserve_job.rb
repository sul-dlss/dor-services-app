# frozen_string_literal: true

# Move an object to Preservation (SDR) in the background
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
      Honeybadger.context(background_job_result_id: background_job_result.id)
      Honeybadger.notify(e)
      return LogFailureJob.perform_later(druid: druid,
                                         background_job_result: background_job_result,
                                         workflow: 'accessionWF',
                                         workflow_process: 'preservation-ingest-initiated',
                                         output: { errors: [{ title: 'Preservation error', detail: e.message }] })
    end

    StartPreservationWorkflowJob.perform_later(druid: druid,
                                               version: item.current_version,
                                               background_job_result: background_job_result)
  end
end
