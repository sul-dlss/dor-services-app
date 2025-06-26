# frozen_string_literal: true

# Base controller for workflow controllers
class WorkflowApplicationController < ApplicationController
  rescue_from Dor::MissingWorkflowException, with: :resource_not_found
  rescue_from WorkflowService::NotFoundException, with: :resource_not_found

  rescue_from(Dor::WorkflowException) do |e|
    status = if (match = e.message&.match(/HTTP status (\d+)/))
               match[1].to_i
             else
               :internal_server_error
             end
    json_api_error(status:, message: e.message)
  end

  rescue_from(WorkflowService::Exception) do |e|
    json_api_error(status: e.status, message: e.message)
  end

  private

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
