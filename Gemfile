# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# DLSS/domain-specific dependencies
gem 'cocina-models', '~> 0.80.0'
gem 'datacite', '~> 0.3.0'
gem 'dor-rights-auth', '>= 1.5.0' # required for new CDL rights
gem 'dor-workflow-client', '~> 4.0'
gem 'druid-tools', '~> 2.2'
gem 'marc'
gem 'moab-versioning', '~> 5.0', require: 'moab/stanford'
gem 'preservation-client', '~> 4.0'
# Pinning stanford-mods since >=3 breaks dor-services.
gem 'stanford-mods', '~> 2.6'

# Ruby general dependencies
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bunny', '~> 2.17' # Send messages to RabbitMQ
gem 'committee', '~> 4.4' # validates Open API spec (OAS)
gem 'config'
gem 'deprecation'
gem 'dry-monads'
gem 'dry-schema', '~> 1.4'
gem 'equivalent-xml' # for diffing MODS
gem 'faraday', '~> 2.0'
gem 'faraday-retry'
gem 'honeybadger'
gem 'jbuilder'
gem 'jwt' # json web token
gem 'lograge'
gem 'okcomputer'
gem 'parallel' # used for validating cocina tools
gem 'pg'
gem 'progressbar' # for the cleaner rake task
gem 'puma', '~> 5.3' # app server
gem 'rails', '~> 6.1'
gem 'retries' # for Goobi
gem 'rsolr'
gem 'ruby-cache', '~> 0.3.0'
gem 'sidekiq', '~> 6.0'
gem 'sidekiq-statistic'
gem 'tty-progressbar' # to show progress when running migration script
gem 'uuidtools', '~> 2.1.4'
gem 'whenever', require: false

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'marc-vocab' # used by bin/reports/report-desc-marcgac
  gem 'rubyzip', '>= 1.0.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

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
