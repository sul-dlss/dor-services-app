# frozen_string_literal: true

server 'dor-services-prod.stanford.edu', user: 'dor_services', roles: %w(web app)
server 'dor-services-worker-prod-a.stanford.edu', user: 'dor_services', roles: %w(app worker)
server 'dor-services-worker-prod-b.stanford.edu', user: 'dor_services', roles: %w(app worker)

Capistrano::OneTimeKey.generate_one_time_key!
