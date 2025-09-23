# frozen_string_literal: true

# Common superclass for all jobs
class ApplicationJob < ActiveJob::Base
  # See config/initializers/sidekiq.rb for explanation.
  sidekiq_options pool: REDIS
end
