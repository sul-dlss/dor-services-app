# frozen_string_literal: true

# Invokes the ResetWorkspaceService
class ResetWorkspaceJob < ApplicationJob
  queue_as :low

  # @param [String] druid the identifier of the object to be reset
  # @param [Integer] version the version of the object to be reset
  def perform(druid:, version:)
    ResetWorkspaceService.reset(druid:, version:)
  rescue ResetWorkspaceService::DirectoryAlreadyExists
    # We're trapping errors and doing nothing, because the belief is that these indicate
    # this API has already been called and completed.
  end
end
