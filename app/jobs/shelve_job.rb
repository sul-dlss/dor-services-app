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
      ShelvingService.shelve(item)
    rescue ShelvingService::ContentDirNotFoundError => e
      background_job_result.output = { errors: [{ title: 'Content directory not found', detail: e.message }] }
      background_job_result.complete!
    end

    # These two lines should be unnecessary, but we are getting:
    #   "PG::ConnectionBad: PQconsumeInput() could not receive data from server: Connection timed out"
    # and "PG::UnableToSend: server closed the connection unexpectedly This probably means the server terminated abnormally before or while processing the request"
    ActiveRecord::Base.connection_pool.release_connection
    ActiveRecord::Base.connection_pool.with_connection do
      background_job_result.complete!
    end
  end
end
