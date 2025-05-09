# frozen_string_literal: true

server 'dor-services-app-prod-a.stanford.edu', user: 'dor_services', roles: %w[web app]
server 'dor-services-app-prod-b.stanford.edu', user: 'dor_services', roles: %w[web app]
server 'dor-services-worker-prod-a.stanford.edu', user: 'dor_services', roles: %w[app worker scheduler]
server 'dor-services-worker-prod-b.stanford.edu', user: 'dor_services', roles: %w[app worker rolling_indexer]
