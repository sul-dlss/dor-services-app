# frozen_string_literal: true

# Invokes the ResetWorkspaceService
class ResetWorkspaceJob < ApplicationJob
  queue_as :default

  WORKFLOW_PROCESS = 'reset-workspace'

  # @param [String] druid the identifier of the object to be reset
  # @param [Integer] version the version of the object to be reset
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  # @param [String] workflow Which workflow should this be reported to?
  def perform(druid:, version:, background_job_result:, workflow:)
    background_job_result.processing!

    begin
      ResetWorkspaceService.reset(druid:, version:)
    rescue ResetWorkspaceService::DirectoryAlreadyExists
      # We're trapping errors and doing nothing, because the belief is that these indicate
      # this API has already been called and completed.
    rescue StandardError => e
      return LogFailureJob.perform_later(druid:,
                                         background_job_result:,
                                         workflow:,
                                         workflow_process: WORKFLOW_PROCESS,
                                         output: { errors: [{ title: 'Unable to reset workspace', detail: e.message }] })
    end

    LogSuccessJob.perform_later(druid:,
                                workflow:,
                                background_job_result:,
                                workflow_process: WORKFLOW_PROCESS)
  end
end
