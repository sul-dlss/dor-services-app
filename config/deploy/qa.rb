# frozen_string_literal: true

server 'dor-services-app-qa-a.stanford.edu', user: 'dor_services', roles: %w[web app]
server 'dor-services-app-qa-b.stanford.edu', user: 'dor_services', roles: %w[web app]
server 'dor-services-worker-qa-a.stanford.edu', user: 'dor_services', roles: %w[app worker scheduler rolling_indexer]

Capistrano::OneTimeKey.generate_one_time_key!
