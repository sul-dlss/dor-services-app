# frozen_string_literal: true

Sidekiq.configure_server do |config|
  # Add the following to a sidekiq.yml to have it handle robot jobs.
  # :labels:
  #   - robot
  if config[:labels].include?('robot')
    config.redis = { url: Settings.robots_redis_url }
    # For Sidekiq Pro
    config.super_fetch!
  else
    config.redis = { url: Settings.redis_url }
  end
end

# The redis instance is also set in ApplicationJob.
# This is because we were encountering issues with active jobs
# getting enqueued to the wrong Redis instance.
Sidekiq.configure_client do |config|
  config.redis = { url: Settings.redis_url }
end

# Custom Sidekiq client for robots
ROBOT_SIDEKIQ_CLIENT = Sidekiq::Client.new(
  pool: ConnectionPool.new(size: 10, timeout: 10) do
    Redis.new(
      url: Settings.robots_redis_url,
      connect_timeout: 10, # time to establish TCP
      read_timeout: 5,
      write_timeout: 5,
      reconnect_attempts: 3
    )
  end
)
