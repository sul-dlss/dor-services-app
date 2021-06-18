# frozen_string_literal: true

# Cleanup files from the workspace in the background
class CleanupJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    background_job_result.processing!

    begin
      CleanupService.cleanup_by_druid druid

      # Shelving can take a long time and can cause the database connections to get stale.
      # So reset to avoid: ActiveRecord::StatementInvalid: PG::ConnectionBad: PQconsumeInput() could not receive data from server: Connection timed out : BEGIN
      ActiveRecord::Base.clear_active_connections!
      EventFactory.create(druid: druid, event_type: 'end-accession complete', data: { background_job_result_id: background_job_result.id })
    rescue StandardError => e
      return LogFailureJob.perform_later(druid: druid,
                                         background_job_result: background_job_result,
                                         workflow: 'accessionWF',
                                         workflow_process: 'end-accession',
                                         output: { errors: [{ title: 'Unable to cleanup workspace', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid: druid,
                                workflow: 'accessionWF',
                                background_job_result: background_job_result,
                                workflow_process: 'end-accession')
  end
end
