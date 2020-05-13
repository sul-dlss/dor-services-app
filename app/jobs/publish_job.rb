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
    workflow_process = workflow == 'releaseWF' ? 'release-publish' : 'publish'
    begin
      item = Dor.find(druid)

      # Disabling validation until pre-assembly and WAS handle this correctly.
      # validator = validator_for?(item)
      # unless validator.valid?
      # Honeybadger.notify("Not all files for '#{druid}' have dark access and/or are unshelved when item access is dark: #{validator.invalid_filenames}")
      # return LogFailureJob.perform_later(druid: druid,
      #                                    background_job_result: background_job_result,
      #                                    workflow: workflow,
      #                                    workflow_process: workflow_process,
      #                                    output: { errors: [{ title: 'Access mismatch',
      #                                                         detail: "Not all files have dark access and/or are unshelved when item access is dark: #{validator.invalid_filenames}" }] })
      # end

      PublishMetadataService.publish(item)
      EventFactory.create(druid: druid, event_type: 'publishing_complete', data: { background_job_result_id: background_job_result.id })
    rescue Dor::DataError => e
      return LogFailureJob.perform_later(druid: druid,
                                         background_job_result: background_job_result,
                                         workflow: workflow,
                                         workflow_process: workflow_process,
                                         output: { errors: [{ title: 'Data error', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid: druid,
                                background_job_result: background_job_result,
                                workflow: workflow,
                                workflow_process: workflow_process)
  end

  def validator_for?(item)
    model = Cocina::Mapper.build(item)
    ValidateDarkService.new(model)
  end
end
