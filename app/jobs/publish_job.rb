# frozen_string_literal: true

# Create virtual objects in the background.
# Both accessionWF and releaseWF use this step.
class PublishJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  # @param [String] workflow Which workflow should this be reported to?
  def perform(druid:, background_job_result:, workflow:)
    background_job_result.processing!

    Dor::Config.workflow.client.update_status(druid: druid,
                                              workflow: workflow,
                                              process: 'publish-complete',
                                              status: 'started',
                                              elapsed: 1,
                                              note: Socket.gethostname)

    begin
      item = Dor.find(druid)
      PublishMetadataService.publish(item)
    rescue Dor::DataError => e
      return LogFailureJob.perform_later(druid: druid,
                                         background_job_result: background_job_result,
                                         workflow: workflow,
                                         workflow_process: 'publish-complete',
                                         output: { errors: [{ title: 'Data error', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid: druid,
                                background_job_result: background_job_result,
                                workflow: workflow,
                                workflow_process: 'publish-complete')
  end
end
