# frozen_string_literal: true

# This initializes the workflow client with values from settings
class WorkflowClientFactory
  def self.build
    logger = if Settings.workflow.logfile == 'rails'
               Rails.logger
             else
               Logger.new(Settings.workflow.logfile, Settings.workflow.shift_age)
             end
    Dor::Workflow::Client.new(url: Settings.workflow_url, logger: logger, timeout: Settings.workflow.timeout)
  end
end
