source 'https://rubygems.org'

# Ruby general dependencies
gem 'grape', '~> 0.14'
gem 'rack-test'

gem 'faraday'
gem 'rest-client'

# DLSS/domain-specific dependencies
gem 'dor-services', '~> 5.12'
gem 'activesupport', '~> 4.2'
gem 'lyber-core', '>= 2.0.2'
gem 'workflow-archiver', '~> 2.0'

group :production do
  gem 'ruby-oci8'
end

group :test, :development do
  gem 'rspec'
  gem 'coveralls', require: false
  gem 'simplecov'
  gem 'equivalent-xml'
  gem 'fakeweb'
  gem 'rack-console'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'equivalent-xml'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano'
end
