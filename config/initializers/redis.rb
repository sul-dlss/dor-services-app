# frozen_string_literal: true

pool_size = ENV.fetch('RAILS_MAX_THREADS', 5)

# This connection pool is used by ReindexJob for unique jobs.
REDIS = ConnectionPool.new(size: pool_size) do
  Redis.new(url: Settings.redis_url, timeout: 5)
end
