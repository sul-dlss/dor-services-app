# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 7.1.0'

# DLSS/domain-specific dependencies
gem 'cocina-models', '~> 0.95.0'
gem 'datacite', '~> 0.3.0'
gem 'dor_indexing', '~> 2.0'
gem 'dor-workflow-client', '~> 7.0'
gem 'druid-tools', '~> 2.2'
gem 'folio_client', '~> 0.8'
gem 'graphql'
gem 'mais_orcid_client'
gem 'marc'
gem 'moab-versioning', '~> 6.0', require: 'moab/stanford'
gem 'preservation-client', '~> 6.0'
gem 'sul_orcid_client', '~> 0.3'

# Ruby general dependencies
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bunny', '~> 2.17' # Send messages to RabbitMQ
gem 'committee' # validates Open API spec (OAS)
gem 'config'
gem 'daemons' # for rolling indexer
gem 'dry-monads'
gem 'edtf', '~> 3.0' # used for metadata reports
gem 'equivalent-xml' # for diffing MODS
gem 'faraday', '~> 2.0'
gem 'faraday-retry'
gem 'honeybadger'
gem 'jbuilder'
gem 'jsonpath', '~> 1.1' # used for metadata reports
gem 'jwt' # json web token
gem 'lograge'
gem 'okcomputer'
gem 'parallel' # used for validating cocina tools and for rolling indexer
gem 'pg'
gem 'retries' # for Goobi
gem 'rsolr'
gem 'rss', '~> 0.2' # Provides Time.w3cdtf used for BadW3cdtfDates report
gem 'ruby-cache', '~> 0.3.0'
gem 'sidekiq', '~> 7.0'
gem 'sneakers', '~> 2.11'
gem 'tty-progressbar' # to show progress when running validate-cocina script
gem 'uuidtools', '~> 2.1.4'
gem 'whenever', require: false

group :test, :development do
  gem 'debug'
  gem 'diffy'
  # NOTE: factory_bot_rails >= 6.3.0 requires env/test.rb to have config.factory_bot.reject_primary_key_attributes = false
  gem 'factory_bot_rails'
  gem 'rack-console'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'simplecov'
  gem 'webmock'
end

group :development do
  gem 'graphiql-rails' # GraphQL IDE
  gem 'puma', '~> 6.0' # app server for dev
  gem 'sass-rails' # for GraphiQL
end

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano', require: false
end
