# frozen_string_literal: true

# Sidekiq.configure_server do |config|
#   config.redis = { url: Settings.redis_url }
#   # For Sidekiq Pro
#   config.super_fetch!
# end

Sidekiq.configure_server do |config|
  Rails.logger.info("Sidekiq labels: #{config[:labels].to_a}")
  config.redis = { url: Settings.redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: Settings.redis_url }
end
