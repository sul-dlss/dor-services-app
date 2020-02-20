# frozen_string_literal: true

require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "action_controller/railtie"
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
      { "Content-Type" => "application/vnd.api+json" },
      [JSON.generate(error_body)]
    ]
  end
end

module DorServices
  class Application < Rails::Application
    accept_proc = proc { |request| request.path.start_with?('/v1') }
    config.middleware.use Committee::Middleware::RequestValidation, schema_path: 'openapi.yml', strict: true,
                                                                    error_class: JSONAPIError, accept_request_filter: accept_proc

    # TODO: we can uncomment this at a later date to ensure we are passing back valid responses
    # config.middleware.use Committee::Middleware::ResponseValidation, schema: schema

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # If an object isn't found in DOR, return a 404
    config.action_dispatch.rescue_responses.merge!(
      "ActiveFedora::ObjectNotFoundError" => :not_found
    )

    # This makes sure our Postgres enums function are persisted to the schema
    config.active_record.schema_format = :sql
  end
end
