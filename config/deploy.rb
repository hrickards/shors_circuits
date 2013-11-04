# Copied from http://ariejan.net/2011/09/14/lighting-fast-zero-downtime-deployments-with-git-capistrano-nginx-and-unicorn/

# Bundler integration
require "bundler/capistrano"

set :application,     "shors_circuits"
set :repository,      "git@github.com:hrickards/shors_circuits.git"
set :branch,          "origin/master"
set :migrate_target,  :current
set :padrino_env,       "production"
set :deploy_to,       "/home/deployer/apps/shors_circuits"

set :user,            "deployer"
set :group,           "deployer"
set :use_sudo,        false

role :web,            "vps"
role :app,            "vps"
role :db,             "vps", primary: true

set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

default_environment["PADRINO_ENV"] = 'production'
default_run_options[:shell] = 'bash'
default_run_options[:pty] = true
ssh_options[:forward_agent] = true

namespace :deploy do
  desc "Deploy application"
  task :default do
    update
    # Precompile assets
    precompile
    restart
  end

  desc "Deploy application without reprecompiling assets"
  task :quick do
    update
    restart
  end

  desc "Setup your git-based deployment app"
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    run "git clone #{repository} #{current_path}"
    run "mkdir -p #{releases_path}"
    run "ln -s #{current_path} #{releases_path}/current"

    symlink
    bundle.install
    import
  end

  desc "Import some example data"
  task :import do
    rake "data:import"
  end

  task :cold do
    update
    migrate
  end

  task :update do
    transaction do
      update_code
    end
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    finalize_update
  end

  desc "Update the database (overwritten to avoid symlink)"
  task :migrations do
    transaction do
      update_code
    end
    migrate
    restart
  end

  desc "finalise update"
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # symlink folders
    symlink
  end

  desc "precompile assets"
  task :precompile, :except => { :no_release => true } do
    rake "assets:compile"
  end

  desc "symlink folders"
  task :symlink do
    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    run <<-CMD
      mkdir -p #{latest_release}/tmp &&
      mkdir -p #{shared_path}/compiled &&
      ln -sf #{shared_path}/compiled #{latest_release}/public/compiled && 
      ln -sf #{shared_path}/application.yml #{latest_release}/config/application.yml &&
      ln -sf #{shared_path}/user.yml #{latest_release}/lib/tasks/ &&
      ln -sf #{shared_path}/unicorn.rb #{latest_release}/config/unicorn.rb
    CMD
  end

  desc "Zero-downtime restart of Unicorn"
  task :restart, :except => { :no_release => true } do
    run "kill -s USR2 `cat /tmp/unicorn.shor.pid`"
  end

  desc "Start unicorn"
  task :start, :except => { :no_release => true } do
    run "cd #{current_path} ; bundle exec unicorn -c #{current_path}/config/unicorn.rb -D"
  end

  desc "Stop unicorn"
  task :stop, :except => { :no_release => true } do
    run "kill -s QUIT `cat /tmp/unicorn.shor.pid`"
  end

  namespace :rollback do
    desc "Moves the repo back to the previous version of HEAD"
    task :repo, :except => { :no_release => true } do
      set :branch, "HEAD@{1}"
      deploy.default
    end

    desc "Rewrite reflog so HEAD@{1} will continue to point to at the next previous release."
    task :cleanup, :except => { :no_release => true } do
      run "cd #{current_path}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
    end

    desc "Rolls back to the previously deployed version."
    task :default do
      rollback.repo
      rollback.cleanup
    end
  end
end

def rake(cmd)
  run "cd #{current_path}; bundle exec padrino rake #{cmd} -e production"
end
