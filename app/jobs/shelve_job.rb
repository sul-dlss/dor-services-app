# frozen_string_literal: true

# Move files to Stacks in the background
class ShelveJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    background_job_result.processing!

    begin
      cocina_object = CocinaObjectStore.find(druid)

      # Disabling validation until pre-assembly and WAS handle this correctly.
      # validator = validator_for?(item)
      # unless validator.valid?
      # Honeybadger.notify("Not all files for '#{druid}' have dark access and/or are unshelved when item access is dark: #{validator.invalid_filenames}")
      # return LogFailureJob.perform_later(druid: druid,
      #                                    background_job_result: background_job_result,
      #                                    workflow: 'accessionWF',
      #                                    workflow_process: 'shelve',
      #                                    output: { errors: [{ title: 'Access mismatch',
      #                                                         detail: "Not all files have dark access and/or are unshelved when item access is dark: #{validator.invalid_filenames}" }] })
      # end

      ShelvingService.shelve(cocina_object)

      # Shelving can take a long time and can cause the database connections to get stale.
      # So reset to avoid: ActiveRecord::StatementInvalid: PG::ConnectionBad: PQconsumeInput() could not receive data from server: Connection timed out : BEGIN
      ActiveRecord::Base.clear_active_connections!
      EventFactory.create(druid: druid, event_type: 'shelving_complete', data: { background_job_result_id: background_job_result.id })
    rescue ShelvableFilesStager::FileNotFound => e
      return LogFailureJob.perform_later(druid: druid,
                                         background_job_result: background_job_result,
                                         workflow: 'accessionWF',
                                         workflow_process: 'shelve',
                                         output: { errors: [{ title: 'Unable to shelve files', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid: druid,
                                workflow: 'accessionWF',
                                background_job_result: background_job_result,
                                workflow_process: 'shelve')
  end

  def validator_for?(item)
    model = Cocina::Mapper.build(item)
    Cocina::ValidateDarkService.new(model)
  end
end
