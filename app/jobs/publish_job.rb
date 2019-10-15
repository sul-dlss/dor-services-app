# frozen_string_literal: true

# Create virtual objects in the background
class PublishJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    background_job_result.processing!

    errors = []

    begin
      item = Dor.find(druid)
      PublishMetadataService.publish(item)
    rescue Dor::DataError => e
      errors << { title: 'Data error', detail: e.message }
    end

    background_job_result.output = { errors: errors } if errors.any?

    background_job_result.complete!
  end
end
