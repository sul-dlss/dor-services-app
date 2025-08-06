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

Sidekiq::Client.reliable_push! unless Rails.env.test?

Sidekiq.configure_client do |config|
  config.redis = { url: Settings.redis_url }
end

# Custom Sidekiq client for robots
ROBOT_SIDEKIQ_CLIENT = Sidekiq::Client.new(
  pool: ConnectionPool.new { Redis.new(url: Settings.robots_redis_url, timeout: 5) }
)
