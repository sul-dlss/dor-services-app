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
      parent_id, child_ids = virtual_object.values_at(:parent_id, :child_ids)
      # Update the constituent relationship between the parent and child druids
      result = ConstituentService.new(parent_druid: parent_id).add(child_druids: child_ids)
      # Do not add `nil`s to the errors array as they signify successful
      # creation of the virtual object
      errors << result if result.present?
    rescue ActiveFedora::ObjectNotFoundError, Rubydora::FedoraInvalidRequest, Dor::Exception, Preservation::Client::Error => e
      errors << { parent_id => [e.message] }
    rescue StandardError => e
      errors << { parent_id => [e.message] }
    end
  ensure
    background_job_result.output = { errors: errors } if errors.any?
    background_job_result.complete!
  end
end
