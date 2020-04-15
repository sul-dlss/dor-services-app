# frozen_string_literal: true

namespace :sidekiq do
  desc 'Quiet Sidekiq (stop fetching new tasks from Redis)'
  task :quiet do
    on roles(:worker) do
      sudo :systemctl, 'reload', 'sidekiq-*', raise_on_non_zero_exit: false
    end
  end

  desc 'Stop Sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)'
  task :stop do
    on roles(:worker) do
      sudo :systemctl, 'stop', 'sidekiq-*'
    end
  end

  desc 'Start Sidekiq'
  task :start do
    on roles(:worker) do
      sudo :systemctl, 'start', 'sidekiq-*'
    end
  end

  desc 'Restart Sidekiq'
  task :restart do
    on roles(:worker) do
      sudo :systemctl, 'restart', 'sidekiq-*', raise_on_non_zero_exit: false
    end
  end
end
