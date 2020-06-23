# frozen_string_literal: true

server 'dor-services-qa.stanford.edu', user: 'dor_services', roles: %w(web app scheduler)
server 'dor-services-worker-qa-a.stanford.edu', user: 'dor_services', roles: %w(app worker)

Capistrano::OneTimeKey.generate_one_time_key!
