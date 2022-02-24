# frozen_string_literal: true

server 'dor-services-migrate.stanford.edu', user: 'dor_services', roles: %w[web app]

Capistrano::OneTimeKey.generate_one_time_key!
