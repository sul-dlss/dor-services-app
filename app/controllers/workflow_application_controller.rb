# frozen_string_literal: true

# Base controller for workflow controllers
class WorkflowApplicationController < ApplicationController
  rescue_from Workflow::Service::NotFoundException, with: :resource_not_found

  rescue_from(Workflow::Service::Exception) do |e|
    json_api_error(status: e.status, message: e.message)
  end
end
