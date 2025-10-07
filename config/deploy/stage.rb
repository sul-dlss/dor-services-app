# frozen_string_literal: true

server 'dor-services-app-stage-a.stanford.edu', user: 'dor_services', roles: %w[web app]
server 'dor-services-app-stage-b.stanford.edu', user: 'dor_services', roles: %w[web app]
server 'dor-services-worker-stage-a.stanford.edu', user: 'dor_services', roles: %w[app worker scheduler]
