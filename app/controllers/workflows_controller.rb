# frozen_string_literal: true

class WorkflowsController < ApplicationController
  def initial
    Honeybadger.notify("Call to deprecated API #{request.path}. The workflow server now knows about initial_workflow")
    render content_type: 'application/xml', body: Dor::WorkflowObject.initial_workflow(params[:wf_name])
  end
end
