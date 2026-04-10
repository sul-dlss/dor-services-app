# frozen_string_literal: true

# Reindexes an object.
#
# NOTE: INFO-level logging is filtered out when this job runs due to ApplicationJob::IgnoreReindexingLogSubscriber
class ReindexJob < ApplicationJob
  class DeadLockError < StandardError; end

  queue_as :low

  # Retry at ~3 seconds, ~18 seconds, ~83 seconds. If all attempts fail, the error is swallowed not bubbled up.
  retry_on DeadLockError, attempts: 3, wait: :polynomially_longer, queue: :low do |_job, _error|
    nil # do nothing
  end
  # ActiveJob retries are used instead of Sidekiq retries. Bump up log level to filter out start/end job logging
  sidekiq_options retry: false, log_level: :warn

  # @param [String] druid
  # @param [String] trace_id the trace id
  def perform(druid:, trace_id:, current_as_of: nil)
    # Skip reindexing if the current_as_of timestamp in Solr is more recent than the current_as_of timestamp passed in.
    # This avoids redundant reindexing.
    return if skip?(druid:, current_as_of:, trace_id:)

    # Reindexing should be fast, so timeout is only 30 seconds.
    raise DeadLockError unless RedisLock.with_lock(key: "reindex-#{druid}", lock_timeout: 30) do
      cocina_object = CocinaObjectStore.find(druid, validate: false)
      Rails.logger.error("Starting reindexing #{druid} - trace_id #{trace_id}")
      Indexer.reindex(cocina_object:, trace_id:, current_as_of: current_as_of)
    rescue CocinaObjectStore::CocinaObjectStoreError => e
      Rails.logger.error("Error reindexing #{druid} - trace_id #{trace_id}: #{e.message}")
      Honeybadger.notify(e, context: { druid:, trace_id: })
    end
  end

  def skip?(druid:, current_as_of:, trace_id:)
    return false unless current_as_of

    results = SolrService.query("id:\"#{druid}\"", fl: 'current_as_of_dttsi', rows: 1)
    return false if results.empty?

    solr_timestamp = results.first['current_as_of_dttsi'].then { |ts| Time.zone.parse(ts) if ts }
    return false unless solr_timestamp

    (solr_timestamp > current_as_of).tap do |skip|
      if skip
        Rails.logger.info(
          "Skipping reindexing #{druid} - #{trace_id}: " \
          "current_as_of_dttsi (#{solr_timestamp.iso8601(6)}) > " \
          "current_as_of (#{current_as_of.iso8601(6)})."
        )
      end
    end
  end
end
