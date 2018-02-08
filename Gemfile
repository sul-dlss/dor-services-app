source 'https://rubygems.org'

gem 'rails', '~> 5.1.0'

# Use Puma as the app server
gem 'puma', '~> 3.0'

# requirement for rdf-rdfa / haml gem
gem 'erubis'

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

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Ruby general dependencies
gem 'okcomputer'
gem 'config'
gem 'honeybadger'

gem 'faraday'
gem 'rest-client'
gem 'marc'

# DLSS/domain-specific dependencies
gem 'dor-services', '~> 5.12'
gem 'lyber-core', '>= 2.0.2'
gem 'workflow-archiver', '~> 2.0'

group :production do
  gem 'ruby-oci8'
end

group :test, :development do
  gem 'rspec-rails'
  gem 'rails-controller-testing'
  gem 'coveralls', require: false
  gem 'simplecov'
  gem 'equivalent-xml'
  gem 'fakeweb'
  gem 'rack-console'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'capybara'
end

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano'
end
