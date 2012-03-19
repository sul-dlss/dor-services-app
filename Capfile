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
require 'dlss/capistrano'

set :application,      "dor-services-app"
set :rvm_ruby_string, "1.8.7@#{application}"

task :dev do
  role :app, "sul-lyberservices-dev.stanford.edu"
  set :bundle_without, []                         # install all the bundler groups in dev
end

task :testing do
  role :app, "lyberservices-test.stanford.edu"
end

task :production do
  role :app, "sul-lyberservices-prod.stanford.edu"
end

set :user, "lyberadmin" 
set :repository,  "/afs/ir/dev/dlss/git/lyberteam/dor-services-app.git"
set :sunetid,   Capistrano::CLI.ui.ask('SUNetID: ') { |q| q.default =  `whoami`.chomp }
set :local_repository, "ssh://#{sunetid}@corn.stanford.edu#{repository}"
set :deploy_to, "/home/#{user}/#{application}"

set :shared_config_certs_dir, true

after "deploy:symlink", "dor_services_app:trust_rvmrc"

namespace :dor_services_app do
  task :trust_rvmrc do
    run "rvmrc trust #{latest_release}"
  end
end

namespace :deploy do
  task :start, :roles => :app do
      run "touch #{current_release}/tmp/restart.txt"
  end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_release}/tmp/restart.txt"
  end
end