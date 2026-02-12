# frozen_string_literal: true

# Common superclass for all jobs
class ApplicationJob < ActiveJob::Base
  # ActiveJob's default LogSubscriber logs too verbosely in reindexing
  # situations, and ActiveJob does not provide hooks for changing the log level
  # for a particular job or tweaking these log entries.
  #
  # Instead, we replace the default LogSubscriber with our own that suppresses reindexing job logging.
  #
  # NOTE: The ActiveJob log subscriber API will have breaking changes in Rails 8.2.x, so this will need updating.
  class IgnoreReindexingLogSubscriber < ActiveJob::LogSubscriber
    # Our no-op method we inject when the job is a reindexing job
    def ignore_info(...); end

    def enqueue(event)
      suppress_info_logs!(event)
      super
    end

    def enqueue_at(event)
      suppress_info_logs!(event)
      super
    end

    def perform_start(event)
      suppress_info_logs!(event)
      super
    end

    def perform(event)
      suppress_info_logs!(event)
      super
    end

    def enqueue_retry(event)
      suppress_info_logs!(event)
      super
    end

    private

    def suppress_info_logs!(event)
      if event.payload[:job].is_a?(ReindexJob) || event.payload[:job].is_a?(BatchReindexJob)
        unless already_suppressing_info_logs?
          # Store the reference to the vanilla `Logger#info` method for later
          # restoration in non-reindexing jobs
          alias original_info info
          # Override `#info` to suppress printing info-level log statements
          alias info ignore_info
          # puts "original alias in place? #{respond_to?(:original_info, include_private: true)}"
        end
      elsif respond_to?(:original_info, include_private: true)
        unless already_restored_info_logs?
          # Restore the original `#info` so other jobs don't have INFO log entries
          # suppressed
          alias info original_info
        end
      end
    end

    def already_suppressing_info_logs?
      method(:info) == method(:ignore_info)
    end

    def already_restored_info_logs?
      method(:info) == method(:original_info)
    end
  end

  ActiveJob::LogSubscriber.detach_from :active_job
  IgnoreReindexingLogSubscriber.attach_to :active_job
end
