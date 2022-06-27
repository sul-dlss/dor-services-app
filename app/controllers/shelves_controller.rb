# frozen_string_literal: true

# API to move files to Stacks
class ShelvesController < ApplicationController
  before_action :load_cocina_object, only: :create

  def create
    if @cocina_object.dro?
      result = BackgroundJobResult.create
      EventFactory.create(druid: @cocina_object.externalIdentifier, event_type: 'shelve_request_received', data: { background_job_result_id: result.id })
      queue = params['lane-id'] == 'low' ? :low : :default

      ShelveJob.set(queue:).perform_later(druid: @cocina_object.externalIdentifier, background_job_result: result)
      head :created, location: result
    else
      render json: {
               errors: [
                 { title: 'Invalid item type', detail: "A DRO is required but you provided '#{@cocina_object.type}'" }
               ]
             }, status: :unprocessable_entity
    end
  end
end
