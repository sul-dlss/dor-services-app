source 'https://rubygems.org'

# Ruby general dependencies
gem 'grape', '~> 0.14'
gem 'rack-test'

# DLSS/domain-specific dependencies
gem 'dor-services', '~> 5.9', '>= 5.9.0'
gem 'lyber-core', '>= 2.0.2'
gem 'workflow-archiver', '~> 2.0'

group :production do
  gem 'ruby-oci8'
end

group :test, :development do
  gem 'rspec'
  gem 'simplecov'
  gem 'equivalent-xml'
  gem 'fakeweb'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano'
end
