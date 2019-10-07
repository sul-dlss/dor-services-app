# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '~> 5.2.0'

# Use Puma as the app server
gem 'puma', '~> 3.0'

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
gem 'config'
gem 'deprecation'
gem 'dry-struct'
gem 'dry-types'
gem 'faraday'
gem 'honeybadger'
gem 'jbuilder'
gem 'jwt'
gem 'net-http-persistent', '~> 2.9' # Pin to avoid problem exhausting file handles under load
gem 'okcomputer'
gem 'pg'
gem 'progressbar' # for the cleaner rake task
gem 'ruby-cache', '~> 0.3.0'
gem 'sidekiq', '~> 5.2'
gem 'sidekiq-statistic'
gem 'uuidtools', '~> 2.1.4'

# DLSS/domain-specific dependencies
gem 'cocina-models', '~> 0.4.0'
gem 'dor-services', '~> 8.0'
gem 'dor-workflow-client', '~> 3.9'
gem 'marc'
gem 'moab-versioning', '~> 4.0', require: 'moab/stanford'
gem 'preservation-client'

group :test, :development do
  gem 'coveralls', '~> 0.8', require: false
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'rack-console'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'rubocop', '~> 0.74.0'
  gem 'rubocop-rails'
  gem 'rubocop-rspec', '~> 1.32.0'
  gem 'simplecov'
  gem 'webmock'
end

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shared_configs'
  gem 'capistrano-sidekiq'
  gem 'dlss-capistrano'
end
