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
gem 'okcomputer'
gem 'config'
gem 'honeybadger'

gem 'faraday'
gem 'rest-client'
# Pin net-http-persistent to avoid a problem with exhausting file handles when running under load
gem 'net-http-persistent', '~> 2.9'
gem 'marc'
gem 'uuidtools', '~> 2.1.4'

# DLSS/domain-specific dependencies
gem 'dor-services', '~> 6.1'
gem 'lyber-core', '>= 2.0.2'
gem 'workflow-archiver', '~> 3.0'

group :production do
  gem 'ruby-oci8'
end

group :test, :development do
  gem 'rspec-rails'
  gem 'rails-controller-testing'
  gem 'coveralls', '~> 0.8', require: false
  gem 'simplecov'
  gem 'equivalent-xml'
  gem 'rack-console'
  gem 'rubocop', '~> 0.65.0'
  gem 'rubocop-rspec', '~> 1.32.0'
  gem 'webmock'
end

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano'
end
