# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '~> 5.2.0'

# Use Puma as the app server
gem 'puma', '~> 3.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
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
gem 'honeybadger'
gem 'okcomputer'

gem 'faraday'
gem 'jwt'
gem 'marc'
gem 'rest-client'
gem 'ruby-cache', '~> 0.3.0'
# Pin net-http-persistent to avoid a problem with exhausting file handles when running under load
gem 'net-http-persistent', '~> 2.9'
gem 'progressbar' # for the cleaner rake task
gem 'uuidtools', '~> 2.1.4'

# DLSS/domain-specific dependencies
gem 'dor-services', '~> 7.0'

group :test, :development do
  gem 'coveralls', '~> 0.8', require: false
  gem 'equivalent-xml'
  gem 'rack-console'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rubocop', '~> 0.65.0'
  gem 'rubocop-rspec', '~> 1.32.0'
  gem 'simplecov'
  gem 'webmock'
end

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano'
end
