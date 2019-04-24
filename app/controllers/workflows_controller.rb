# frozen_string_literal: true

class WorkflowsController < ApplicationController
  def initial
    render content_type: 'application/xml', body: Dor::WorkflowObject.initial_workflow(params[:wf_name])
  end
end
