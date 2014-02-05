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

set :application,  "dor-services-app"

task :dev do
  role :app, "sul-lyberservices-dev.stanford.edu"
  set :bundle_without, []                         # install all the bundler groups in dev
  set :deploy_env, 'development'
end

task :testing do
  role :app, "sul-lyberservices-test.stanford.edu"
  set :deploy_env, 'test'
end

task :production do
  role :app, "sul-lyberservices-prod.stanford.edu"
  set :deploy_env, 'production'
end

set :user, "lyberadmin"
set :home_dir, '/home'
set :repository do
  msg = "Sunetid: "
  sunetid = Capistrano::CLI.ui.ask(msg)
  "ssh://#{sunetid}@corn.stanford.edu/afs/ir/dev/dlss/git/lyberteam/dor-services-app.git"
end
set :deploy_to, "/home/#{user}/#{application}"
set :deploy_via, :copy
set :copy_cache, :true
set :copy_exclude, [".git"]

set :shared_children, %w(log config/environments config/certs)

# Set the shared children before deploy:update
before "deploy:update", "dlss:set_ld_library_path"

namespace :dlss do

  desc <<-DESC
         Sets the shared directories that will be linked to from each release \
         overriding the rails specific defaults from capistrano.  Will create \
         shared/config/certs directory if :shared_config_certs_dir is true. \
         This task is set to run before deploy:setup and deploy:update
  DESC
  task :set_ld_library_path do
     default_environment["LD_LIBRARY_PATH"] = "/usr/lib/oracle/11.2/client64/lib:$LD_LIBRARY_PATH"
  end

end

namespace :deploy do
  desc <<-DESC
        This overrides the default :finalize_update since we don't care about \
        rails specific directories
  DESC
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    shared_children.map do |d|
      run "rm -rf #{latest_release}/#{d}"
      run "ln -s #{shared_path}/#{d.split('/').last} #{latest_release}/#{d}"
    end
  end

  task :start, :roles => :app do
      run "touch #{current_release}/tmp/restart.txt"
  end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_release}/tmp/restart.txt"
  end
end
