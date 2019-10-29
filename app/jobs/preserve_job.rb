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
      background_job_result.output = { errors: [{ title: 'Preservation error', detail: e.message }] }
      background_job_result.complete!
      raise e
    end

    background_job_result.complete!
  end
end
