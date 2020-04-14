# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 5.2.0'

# Use Puma as the app server
gem 'puma', '~> 3.12'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'pry-byebug'
end

group :development do
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Ruby general dependencies
gem 'committee' # validates Open API spec (OAS)
gem 'config'
gem 'deprecation'
gem 'dry-schema', '~> 1.4'
gem 'faraday', '~> 1.0'
gem 'faraday_middleware', '~> 1.0.0.rc1' # dependency of dor-workflow-client. remove when release > 0.14.0
gem 'honeybadger'
# iso-639 0.3.0 isn't compatible with ruby 2.5.  This declaration can be dropped when we upgrade to 2.6
# see https://github.com/alphabetum/iso-639/issues/12
# iso-639 is used by dor-services gem via stanford-mods gem
gem 'iso-639', '~> 0.2.8'
gem 'jbuilder'
gem 'jwt'
gem 'okcomputer'
gem 'openapi_parser'
gem 'pg'
gem 'progressbar' # for the cleaner rake task
gem 'retries' # for ReleaseTags::PurlClient and Goobi
gem 'ruby-cache', '~> 0.3.0'
gem 'sidekiq', '~> 6.0'
gem 'sidekiq-statistic'
gem 'uuidtools', '~> 2.1.4'
gem 'whenever', require: false

# DLSS/domain-specific dependencies
gem 'cocina-models', '~> 0.31.0'
gem 'dor-services', '~> 9.2'
gem 'dor-workflow-client', '~> 3.17'
gem 'marc'
gem 'moab-versioning', '~> 4.0', require: 'moab/stanford'
gem 'preservation-client', '>= 3.0' # 3.x or greater is needed for token auth

group :test, :development do
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'rack-console'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'rubocop', '~> 0.74.0'
  gem 'rubocop-rails'
  gem 'rubocop-rspec', '~> 1.32.0'
  gem 'simplecov', '~> 0.17.1' # https://github.com/codeclimate/test-reporter/issues/413
  gem 'webmock'
end

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano'
end
