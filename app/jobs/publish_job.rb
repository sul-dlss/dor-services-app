# frozen_string_literal: true

# Publish metadata for an object as a background job
# Both accessionWF and releaseWF use this step.
class PublishJob < ApplicationJob
  queue_as :publish_default

  # @param [String] druid the identifier of the item to be published
  # @param [Integer,nil] user_version the version of the item to be published. If nil, the latest version will
  #  be published.
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  # @param [Boolean] release whether to release after publishing
  def perform(druid:, background_job_result:, user_version: nil, release: false)
    background_job_result.processing!
    cocina_object = CocinaObjectStore.find(druid)

    # Note that LogFailureJob / LogSuccessJob will update the BackgroundJobResult.
    # If workflow is nil, no workflow will be reported to.
    if cocina_object.admin_policy?
      background_job_result.output = { errors: [{ title: 'Publishing error',
                                                  detail: 'Cannot publish an admin policy' }] }
      background_job_result.complete!
      return
    end

    Publish::MetadataTransferService.publish(druid:, user_version:)
    EventFactory.create(druid:, event_type: 'publishing_complete',
                        data: { background_job_result_id: background_job_result.id })

    if release
      Workflow::Service.create(druid:, workflow_name: 'releaseWF',
                               version: cocina_object.version)
    end

    background_job_result.complete!
  end
end
