# frozen_string_literal: true

# API to move files to Stacks
class ShelvesController < ApplicationController
  before_action :load_item, only: :create

  def create
    if @item.is_a?(Dor::Item)
      result = BackgroundJobResult.create
      EventFactory.create(druid: @item.pid, event_type: 'shelve_request_received',
                          data: { background_job_result_id: result.id })
      queue = params['lane-id'] == 'low' ? :low : :default

      ShelveJob.set(queue: queue).perform_later(druid: @item.pid, background_job_result: result)
      head :created, location: result
    else
      render json: {
        errors: [
          { title: 'Invalid item type', detail: "A Dor::Item is required but you provided '#{@item.class}'" }
        ]
      }, status: :unprocessable_entity
    end
  end
end
