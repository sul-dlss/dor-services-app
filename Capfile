# Initial setup run from laptop
# 1) Setup directory structure on remote VM
#   $ cap dev deploy:setup
# 2) Manually copy environment specific config file to $application/shared/config/environments.  
#      Only necessary for initial install
# 3) Manually copy certs to $application/shared/config/certs
#      Only necessary for initial install
# 4) Copy project from source control to remote
#   $ cap dev deploy:update
# 
#  Future releases will update the code and restart the app 
#   $ cap dev deploy

load 'deploy' if respond_to?(:namespace) # cap2 differentiator
require 'dlss/capistrano/robots'

set :application,      "dor-services-app"
set :rvm_ruby_string, "1.8.7@#{application}"
set :rvm_type, :system

task :dev do
  role :app, "sul-lyberservices-dev.stanford.edu"
  set :bundle_without, []                         # install all the bundler groups in dev
  set :home_dir, '/home'
end

task :testing do
  role :app, "sul-lyberservices-test.stanford.edu"
  set :home_dir, '/home'
end

task :testing_old do
  set :rvm_type, :user
  role :app, "lyberservices-test.stanford.edu"
  set :home_dir, '/var/opt/home'
end

task :production do
  role :app, "sul-lyberservices-prod.stanford.edu"
  set :home_dir, '/home'
end

set :user, "lyberadmin" 
set :sunetid,   Capistrano::CLI.ui.ask('SUNetID: ') { |q| q.default =  `whoami`.chomp }
set :deploy_via, :copy # I got 99 problems, but AFS ain't one
set :repository, "ssh://#{sunetid}@corn.stanford.edu/afs/ir/dev/dlss/git/lyberteam/dor-services-app.git"
set :deploy_to, "/home/#{user}/#{application}"
set :copy_cache, '/Users/wmene/dev/afsgit/cap_cache/dor-services-app'
set :copy_exclude, [".git"]

set :shared_config_certs_dir, true

after "deploy:symlink", "dor_services_app:trust_rvmrc"

namespace :dor_services_app do
  task :trust_rvmrc do
    run "rvm rvmrc trust \"#{home_dir}/#{user}/#{application}/releases/#{release_name}\""
  end
end

# Override the tasks in 'dlss/capistrano/robots'
namespace :deploy do
  task :start, :roles => :app do
      run "touch #{current_release}/tmp/restart.txt"
  end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_release}/tmp/restart.txt"
  end
end