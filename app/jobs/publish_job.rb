# frozen_string_literal: true

# Publish metadata for an object as a background job
# Both accessionWF and releaseWF use this step.
class PublishJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the fedora_item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  # @param [String] workflow Which workflow should this be reported to?
  def perform(druid:, background_job_result:, workflow:)
    background_job_result.processing!
    workflow_process = workflow == 'releaseWF' ? 'release-publish' : 'publish'
    begin
      cocina_object = CocinaObjectStore.find(druid)

      Publish::MetadataTransferService.publish(cocina_object)
      EventFactory.create(druid:, event_type: 'publishing_complete', data: { background_job_result_id: background_job_result.id })
    end

    LogSuccessJob.perform_later(druid:,
                                background_job_result:,
                                workflow:,
                                workflow_process:)
  end
end
