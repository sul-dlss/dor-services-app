# frozen_string_literal: true

set :application, 'dor_services'
set :repo_url, 'https://github.com/sul-dlss/dor-services-app.git'

# Default branch is :main
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/opt/app/dor_services/#{fetch(:application)}"

# Manage sneakers via systemd (from dlss-capistrano gem)
set :sneakers_systemd_role, :worker
set :sneakers_systemd_use_hooks, true

namespace :rabbitmq do
  desc 'Runs rake rabbitmq:setup'
  task setup: ['deploy:set_rails_env'] do
    on roles(:worker) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'rabbitmq:setup'
        end
      end
    end
  end

  before 'sneakers_systemd:start', 'rabbitmq:setup'
end

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets vendor/bundle config/certs config/settings)
set :linked_files, %w(config/honeybadger.yml config/database.yml)

# Namespace crontab entries by application and stage
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
set :whenever_roles, [:scheduler]

set :passenger_roles, :web
set :rails_env, 'production'

set :sidekiq_systemd_role, :worker
set :sidekiq_systemd_use_hooks, true

# Run db migrations on app servers, not db server
set :migration_role, :app

# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, fetch(:stage)

# update shared_configs before restarting app
before 'deploy:restart', 'shared_configs:update'

# Tasks for managing the rolling indexer
namespace :rolling_indexer do # rubocop:disable Metrics/BlockLength
  desc 'Stop rolling indexer'
  task :stop do
    on roles(:rolling_indexer) do
      sudo :systemctl, 'stop', 'rolling-index'
    end
  end

  desc 'Start rolling indexer'
  task :start do
    on roles(:rolling_indexer) do
      sudo :systemctl, 'start', 'rolling-index'
      sudo :systemctl, 'status', 'rolling-index'
    end
  end

  desc 'Restart rolling indexer'
  task :restart do
    on roles(:rolling_indexer) do
      sudo :systemctl, 'restart', 'rolling-index', raise_on_non_zero_exit: false
      sudo :systemctl, 'status', 'rolling-index'
    end
  end

  desc 'Print status of rolling indexer'
  task :status do
    on roles(:rolling_indexer) do
      sudo :systemctl, 'status', 'rolling-index'
    end
  end
end

after 'deploy:starting', 'rolling_indexer:stop'
after 'deploy:published', 'rolling_indexer:start'
after 'deploy:failed', 'rolling_indexer:restart'
