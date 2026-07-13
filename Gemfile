# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 8.0.0'

# DLSS/domain-specific dependencies
gem 'cocina_display'
gem 'cocina-models'
gem 'datacite', '~> 0.6'
gem 'dor-services-client' # Used for Dor::Services::Response::* & Dor::Services::Client::InvalidCocina classes
gem 'druid-tools'
gem 'folio_client'
gem 'graphql'
gem 'json_schemer-rails'
gem 'lyber-core' # For robots
gem 'mais_orcid_client'
gem 'marc'
gem 'moab-versioning', require: 'moab/stanford'
gem 'preservation-client'
gem 'purl_fetcher-client'
gem 'sul_orcid_client'

source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro'
end

# Ruby general dependencies
gem 'bootsnap', require: false
gem 'bunny' # Send messages to RabbitMQ
gem 'config'
gem 'connection_pool' # Used for redis
gem 'csv'
gem 'dry-monads'
gem 'edtf' # used for metadata reports
gem 'equivalent-xml' # for diffing MODS
gem 'faraday'
gem 'faraday-retry'
gem 'honeybadger'
gem 'janeway-jsonpath' # used for metadata reports
gem 'jbuilder'
gem 'jwt' # json web token
gem 'lograge'
gem 'okcomputer'
gem 'parallel' # used for validating cocina tools
gem 'pg'
gem 'redis', '~> 5.0' # used for unique jobs
gem 'retries' # for Goobi
gem 'rsolr'
gem 'ruby-cache'
gem 'sidekiq', '~> 8.0'
gem 'sneakers'
gem 'sqlite3' # used for Marc dump
gem 'tty-progressbar' # to show progress when running validate-cocina script
gem 'uuidtools'
gem 'whenever', require: false

group :test, :development do
  # Security audit for known security defects in code (use config/brakeman.ignore to ignore issues)
  gem 'brakeman', require: false
  gem 'db-query-matchers'
  gem 'debug'
  gem 'diffy'
  # NOTE: factory_bot_rails >= 6.3.0 requires env/test.rb to have
  # config.factory_bot.reject_primary_key_attributes = false
  gem 'factory_bot_rails'
  gem 'rack-console'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
  gem 'simplecov'
  gem 'webmock'
end

group :development do
  gem 'graphiql-rails' # GraphQL IDE
  gem 'propshaft' # for GraphiQL
  gem 'puma' # app server for dev
end

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano', require: false
end
