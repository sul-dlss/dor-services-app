# frozen_string_literal: true

# Controller for workflow templates
class WorkflowTemplatesController < ApplicationController
  def index
    render json: workflow_client.workflow_templates
  end

  private

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
