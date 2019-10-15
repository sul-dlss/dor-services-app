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
      errors << ConstituentService.new(parent_druid: parent_id).add(child_druids: child_ids)
    rescue ActiveFedora::ObjectNotFoundError, Rubydora::FedoraInvalidRequest, Dor::Exception => e
      errors << { parent_id => [e.message] }
    end

    background_job_result.output = { errors: errors } if errors.any?

    background_job_result.complete!
  end
end
