server 'dor-services-dev.stanford.edu', user: 'dor_services', roles: %w(web app)

Capistrano::OneTimeKey.generate_one_time_key!

set :bundle_without, 'test'
