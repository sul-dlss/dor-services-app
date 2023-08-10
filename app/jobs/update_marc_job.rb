# frozen_string_literal: true

# Add/remove a PURL from a catalog record
# releaseWF uses this step.
class UpdateMarcJob < ApplicationJob
  queue_as :update_marc

  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(cocina_item_json, background_job_result:)
    cocina_item = Cocina::Models.build(JSON.parse(cocina_item_json))
    druid = cocina_item.externalIdentifier
    workflow = 'releaseWF'
    workflow_process = 'update-marc'
    background_job_result.processing!

    begin
      Catalog::UpdateMarc856RecordService.update(cocina_item, thumbnail_service: ThumbnailService.new(cocina_item))
    rescue StandardError => e
      Honeybadger.notify(
        'Error updating Folio record',
        error_message: e.message,
        context: {
          druid: cocina_item.externalIdentifier
        }
      )
      return LogFailureJob.perform_later(druid:,
                                         background_job_result:,
                                         workflow: 'releaseWF',
                                         workflow_process: 'update-marc',
                                         output: { errors: [{ title: 'Update MARC error', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid:,
                                background_job_result:,
                                workflow:,
                                workflow_process:)
  end
end
