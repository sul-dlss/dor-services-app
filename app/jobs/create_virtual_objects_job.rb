# frozen_string_literal: true

# Create virtual objects in the background
class CreateVirtualObjectsJob < ApplicationJob
  queue_as :default

  # @param [Array] virtual_objects an array of hashes representing a batch of virtual objects
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(virtual_objects:, background_job_result:)
    background_job_result.processing!
    errors = []

    virtual_objects.each do |virtual_object|
      virtual_object_id, constituent_ids = virtual_object.values_at(:virtual_object_id, :constituent_ids)
      # Update the constituent relationship between the virtual_object and constituent druids
      result = ConstituentService.new(virtual_object_druid: virtual_object_id,
                                      event_factory: EventFactory).add(constituent_druids: constituent_ids)
      # Do not add `nil`s to the errors array as they signify successful
      # creation of the virtual object
      errors << result if result.present?
    rescue Dor::Exception, Preservation::Client::Error => e
      errors << { virtual_object_id => [e.message] }
    rescue StandardError => e
      errors << { virtual_object_id => [e.message] }
      Honeybadger.notify(e)
    end
  ensure
    background_job_result.output = { errors: errors } if errors.any?
    background_job_result.complete!
  end
end
