# frozen_string_literal: true

server 'dor-services-app-prod-a.stanford.edu', user: 'dor_services', roles: %w[web app]
server 'dor-services-app-prod-b.stanford.edu', user: 'dor_services', roles: %w[web app]
server 'dor-services-worker-prod-a.stanford.edu', user: 'dor_services', roles: %w[app worker scheduler sneakers]
server 'dor-services-worker-prod-b.stanford.edu', user: 'dor_services', roles: %w[app worker sneakers]
server 'dor-services-worker-prod-c.stanford.edu', user: 'dor_services', roles: %w[app worker]
server 'dor-services-worker-prod-d.stanford.edu', user: 'dor_services', roles: %w[app worker]
server 'dor-services-worker-prod-e.stanford.edu', user: 'dor_services', roles: %w[app worker]
