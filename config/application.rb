# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'action_controller/railtie'
require 'active_job/railtie'
require 'active_record/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

class JSONAPIError < Committee::ValidationError
  def error_body
    {
      errors: [
        { status: id, detail: message }
      ]
    }
  end

  def render
    [
      status,
      { 'Content-Type' => 'application/vnd.api+json' },
      [JSON.generate(error_body)]
    ]
  end
end

module DorServices
  class Application < Rails::Application
    accept_proc = proc { |request| request.path.start_with?('/v1') }
    config.middleware.use(
      Committee::Middleware::RequestValidation,
      schema_path: 'openapi.yml',
      strict: true,
      error_class: JSONAPIError,
      accept_request_filter: accept_proc,
      parse_response_by_content_type: false,
      query_hash_key: 'action_dispatch.request.query_parameters'
    )
    # Ensure we are passing back valid responses when running tests
    if Rails.env.test?
      config.middleware.use(
        Committee::Middleware::ResponseValidation,
        schema_path: 'openapi.yml',
        parse_response_by_content_type: true,
        query_hash_key: 'rack.request.query_hash',
        raise: true
      )
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # If an object isn't found in DOR, return a 404
    config.action_dispatch.rescue_responses['ActiveFedora::ObjectNotFoundError'] = :not_found

    # This makes sure our Postgres enums function are persisted to the schema
    config.active_record.schema_format = :sql

    # Set up a session store so we can access the Sidekiq Web UI
    # See: https://github.com/mperham/sidekiq/wiki/Monitoring#rails-api-application-session-configuration
    config.session_store :cookie_store, key: '_dor-services-app_session'
  end
end
