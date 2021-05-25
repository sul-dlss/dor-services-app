# frozen_string_literal: true

# Unpublished Druid in the background
class UnpublishJob < ApplicationJob
  queue_as :default

  def perform(druid:, background_job_result:)
    background_job_result.processing!
    UnpublishService.unpublish(druid: druid)
    EventFactory.create(druid: druid, event_type: 'unpublish_complete', data: { background_job_result_id: background_job_result.id })
  end
end
