# frozen_string_literal: true

# Move web archive files to web archiving stacks in the background
class ShelveJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the object to be shelved
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    background_job_result.processing!

    # Shelve web archive files to web archiving stacks
    unless WasService.crawl?(druid:)
      return LogSuccessJob.perform_later(druid:,
                                         workflow: 'accessionWF',
                                         background_job_result:,
                                         workflow_process: 'shelve')
    end

    begin
      cocina_object = CocinaObjectStore.find(druid)

      WasShelvingService.shelve(cocina_object)

      # Shelving can take a long time and can cause the database connections to get stale.
      # So reset to avoid: ActiveRecord::StatementInvalid: PG::ConnectionBad: PQconsumeInput() could not receive data from server: Connection timed out : BEGIN
      ActiveRecord::Base.connection_handler.clear_active_connections!
      EventFactory.create(druid:, event_type: 'shelving_complete', data: { background_job_result_id: background_job_result.id })
    rescue StandardError => e
      Honeybadger.notify('Error shelving', error_message: e.message, context: { druid: })
      return LogFailureJob.perform_later(druid:,
                                         background_job_result:,
                                         workflow: 'accessionWF',
                                         workflow_process: 'shelve',
                                         output: { errors: [{ title: 'Unable to shelve web archive files', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid:,
                                workflow: 'accessionWF',
                                background_job_result:,
                                workflow_process: 'shelve')
  end
end
