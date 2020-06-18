# frozen_string_literal: true

# Move files to Stacks in the background
class ShelveJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, background_job_result:)
    background_job_result.processing!

    begin
      item = Dor.find(druid)

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

      ShelvingService.shelve(item)
      EventFactory.create(druid: druid, event_type: 'shelving_complete', data: { background_job_result_id: background_job_result.id })
    rescue ShelvingService::ContentDirNotFoundError => e
      return LogFailureJob.perform_later(druid: druid,
                                         background_job_result: background_job_result,
                                         workflow: 'accessionWF',
                                         workflow_process: 'shelve',
                                         output: { errors: [{ title: 'Content directory not found', detail: e.message }] })
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
