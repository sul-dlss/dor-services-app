# frozen_string_literal: true

# Remove all traces of the object's data files from the workspace and export areas in the background
class CleanupJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the object to be shelved
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  # @param [String] workflow Which workflow should this be reported to?
  def perform(druid:, background_job_result:, workflow:)
    background_job_result.processing!

    workflow_process = workflow == 'accessionWF' ? 'end-accession' : 'cleanup'

    begin
      CleanupService.cleanup_by_druid druid

      EventFactory.create(druid:,
                          event_type: 'cleanup-workspace',
                          data: { status: 'success' })
    rescue Errno::ENOENT, Errno::ENOTEMPTY => e
      EventFactory.create(druid:, event_type: 'cleanup-workspace',
                          data: { status: 'failure', message: e.message, backtrace: e.backtrace })
      return LogFailureJob.perform_later(druid:,
                                         background_job_result:,
                                         workflow:,
                                         workflow_process:,
                                         output: { errors: [{ title: 'Unable to cleanup workspace', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid:,
                                workflow:,
                                background_job_result:,
                                workflow_process:)
  end
end
