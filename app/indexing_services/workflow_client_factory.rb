# frozen_string_literal: true

# This initializes the workflow client with values from settings
class WorkflowClientFactory
  def self.build
    Dor::Workflow::Client.new(url: Settings.workflow_url, logger: Rails.logger, timeout: Settings.workflow.timeout)
  end
end
