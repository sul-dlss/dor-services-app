# frozen_string_literal: true

# Cleans up files and workflows when a version is discarded.
class CleanupVersionJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the object to be cleaned up
  # @param [String] version the version of the object to be cleaned up
  def perform(druid:, version:)
    CleanupService.delete_accessioning_workflows(druid, version)
    CleanupService.cleanup_by_druid(druid)

    EventFactory.create(druid:,
                        event_type: 'cleanup-workspace',
                        data: { status: 'success' })
  rescue Errno::ENOENT, Errno::ENOTEMPTY => e
    EventFactory.create(druid:, event_type: 'cleanup-workspace',
                        data: { status: 'failure', message: e.message, backtrace: e.backtrace })
  end
end
