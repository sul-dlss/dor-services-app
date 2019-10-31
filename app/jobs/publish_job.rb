# frozen_string_literal: true

# Create virtual objects in the background
class PublishJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    background_job_result.processing!

    begin
      item = Dor.find(druid)
      PublishMetadataService.publish(item)
    rescue Dor::DataError => e
      return LogFailureJob.perform_later(druid: druid,
                                         background_job_result: background_job_result,
                                         workflow_process: 'publish',
                                         output: { errors: [{ title: 'Data error', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid: druid,
                                background_job_result: background_job_result,
                                workflow_process: 'publish-complete')
  end
end
