# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: Settings.redis_url }
end
