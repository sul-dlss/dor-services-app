# frozen_string_literal: true

# Publish metadata for an object as a background job
# Both accessionWF and releaseWF use this step.
class PublishJob < ApplicationJob
  queue_as :publish_default

  # @param [String] druid the identifier of the item to be published
  # @param [Integer,nil] user_version the version of the item to be published. If nil, the latest version will be published.
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  # @param [String,nil] workflow workflow to report to. If nil, no workflow will be reported to.
  # @param [Boolean] log_success whether success should be logged
  def perform(druid:, background_job_result:, workflow: nil, user_version: nil, log_success: true)
    background_job_result.processing!
    cocina_object = CocinaObjectStore.find(druid)

    # Note that LogFailureJob / LogSuccessJob will update the BackgroundJobResult.
    # If workflow is nil, no workflow will be reported to.
    if cocina_object.admin_policy?
      return LogFailureJob.perform_later(druid:,
                                         background_job_result:,
                                         workflow:,
                                         workflow_process: workflow_process_for(workflow),
                                         output: { errors: [{ title: 'Publishing error', detail: 'Cannot publish an admin policy' }] })
    end

    Publish::MetadataTransferService.publish(druid:, user_version:, workflow:)
    EventFactory.create(druid:, event_type: 'publishing_complete', data: { background_job_result_id: background_job_result.id })
    return unless log_success

    LogSuccessJob.perform_later(druid:,
                                background_job_result:,
                                workflow:,
                                workflow_process: workflow_process_for(workflow))
  end

  def workflow_process_for(workflow)
    workflow == 'releaseWF' ? 'release-publish' : 'publish'
  end
end
