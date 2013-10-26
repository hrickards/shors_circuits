set :application, 'shors_circuits'
set :repo_url, 'git@bitbucket.org:hrickards/shors-circuits.git'

set :deploy_to, "/home/harry/#{fetch(:application)}"
set :scm, :git

set :format, :pretty
set :log_level, :debug

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "/etc/init.d/puma restart #{fetch(:application)}"
    end
  end

  after :updated, :symlink_tmp do
    on roles(:app) do 
      execute "rm -rf #{release_path}/tmp"
      execute "ln -nfs #{shared_path}/tmp #{release_path}/tmp"
      execute "chmod 775 #{shared_path}/tmp"
    end
  end

  after :updated, :symlink_files do
    on roles(:app) do
      execute "ln -s #{shared_path}/application.yml #{release_path}/config/"
      execute "ln -s #{shared_path}/puma.rb #{release_path}/config/"
    end
  end
end
