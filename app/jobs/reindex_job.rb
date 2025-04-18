# frozen_string_literal: true

# Reindexes an object.
class ReindexJob < ApplicationJob
  class DeadLockError < StandardError; end

  queue_as :default

  # ~3 seconds, ~18 seconds, ~83 seconds. If this fails, Sidekiq retries are not used.
  retry_on DeadLockError, attempts: 3, wait: :polynomially_longer, queue: :low
  sidekiq_options retry: false

  # @param [String] druid
  # @param [String] trace_id the trace id
  def perform(druid:, trace_id:)
    # Reindexing should be fast, so timeout is only 30 seconds.
    raise DeadLockError unless RedisLock.with_lock(key: "reindex-#{druid}", lock_timeout: 30) do
      cocina_object = CocinaObjectStore.find(druid)
      Indexer.reindex(cocina_object:, trace_id:)
    rescue CocinaObjectStore::CocinaObjectStoreError => e
      Rails.logger.error("Error reindexing #{druid} - trace_id #{trace_id}: #{e.message}")
      Honeybadger.notify(e, context: { druid:, trace_id: })
    end
  end
end
