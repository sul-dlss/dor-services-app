# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
# require 'rails/test_unit/railtie'
require 'active_support'

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
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    accept_proc = proc { |request| request.path.start_with?('/v1') }
    config.middleware.use(
      Committee::Middleware::RequestValidation,
      schema_path: 'openapi.yml',
      strict: true,
      strict_reference_validation: true,
      error_class: JSONAPIError,
      accept_request_filter: accept_proc,
      parse_response_by_content_type: false,
      query_hash_key: 'action_dispatch.request.query_parameters',
      parameter_overwrite_by_rails_rule: false
    )
    # Ensure we are passing back valid responses when running tests
    if Rails.env.test?
      config.middleware.use(
        Committee::Middleware::ResponseValidation,
        schema_path: 'openapi.yml',
        strict_reference_validation: true,
        parse_response_by_content_type: true,
        query_hash_key: 'rack.request.query_hash',
        raise: true,
        parameter_overwrite_by_rails_rule: false
      )
    end

    config.after_initialize do
      Cocina::Models::Mapping::Purl.base_url = Settings.release.purl_base_url
    end

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    # "unless ..." needed to run Graphiql in development.
    config.api_only = true unless Rails.env.development?

    # This makes sure our Postgres enums function are persisted to the schema
    config.active_record.schema_format = :sql
    # Set up a session store so we can access the Sidekiq Web UI
    # See: https://github.com/mperham/sidekiq/wiki/Monitoring#rails-api-application-session-configuration
    config.session_store :cookie_store, key: '_dor-services-app_session'

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
