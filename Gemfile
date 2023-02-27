# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 7.0'

# DLSS/domain-specific dependencies
gem 'cocina-models', '~> 0.88.0'
gem 'datacite', '~> 0.3.0'
gem 'dor-workflow-client', '~> 5.0'
gem 'druid-tools', '~> 2.2'
gem 'folio_client', '~> 0.5'
gem 'marc'
gem 'moab-versioning', '~> 6.0', require: 'moab/stanford'
gem 'preservation-client', '~> 6.0'
# Pinning stanford-mods since >=3 breaks dor-services.
gem 'stanford-mods', '~> 2.6'

# Ruby general dependencies
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bunny', '~> 2.17' # Send messages to RabbitMQ
gem 'committee', '~> 4.4' # validates Open API spec (OAS)
gem 'config'
gem 'dry-monads'
gem 'edtf', '~> 3.0' # used for metadata reports
gem 'equivalent-xml' # for diffing MODS
gem 'faraday', '~> 2.0'
gem 'faraday-retry'
gem 'honeybadger', '~> 4.12'
gem 'jbuilder'
gem 'jsonpath', '~> 1.1' # used for metadata reports
gem 'jwt' # json web token
gem 'lograge'
gem 'okcomputer'
gem 'parallel' # used for validating cocina tools
gem 'pg'
gem 'puma', '~> 5.3' # app server
gem 'retries' # for Goobi
gem 'rsolr'
gem 'rss', '~> 0.2' # Provides Time.w3cdtf used for BadW3cdtfDates report
gem 'ruby-cache', '~> 0.3.0'
gem 'sidekiq', '~> 6.0'
gem 'sneakers', '~> 2.11'
gem 'tty-progressbar' # to show progress when running validate-cocina script
gem 'uuidtools', '~> 2.1.4'
gem 'whenever', require: false

group :test, :development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'diffy'
  gem 'factory_bot_rails'
  gem 'pry-byebug'
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

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano', require: false
end
