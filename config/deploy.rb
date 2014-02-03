# config valid only for Capistrano 3.1
lock '3.1.0'

set :rvm_ruby_string, :local              # use the same ruby as used locally for deployment
# set :rvm_ruby_string, 'ruby-2.0.0-p247@cloud-status'

set :application, 'cloud-status'
set :repo_url, 'git@github.com:datapipe/cloud-status.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :branch, fetch(:branch, "master")

# Default deploy_to directory is /var/www/app-name
set :deploy_to, '/var/www/cloud-status'

set :unicorn_config, "#{fetch(:deploy_to)}/current/config/unicorn/staging.rb"
set :unicorn_pid, "#{fetch(:deploy_to)}/shared/pids/unicorn.pid"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

before 'deploy', 'rvm1:install:rvm'
before 'deploy', 'rvm1:install:ruby'

namespace :unicorn do
  desc 'Start the Unicorn processes'
  task :start do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec unicorn -c #{fetch(:unicorn_config)} -D"
        end
      end
    end
  end

  desc 'Stop the Unicorn processes'
  task :stop do
    on roles(:app) do
      if test("[ -f #{fetch(:unicorn_pid)} ]")
        execute :kill, capture(:cat, fetch(:unicorn_pid))
      end
    end
  end

  desc 'Restart the Unicorn processes'
  task :reload do
    on roles(:app) do
      if test("[ -f #{fetch(:unicorn_pid)} ]")
        execute :kill, '-s USR2', capture(:cat, fetch(:unicorn_pid))
      else
        error 'Unicorn process not running'
      end
    end
  end
end

after 'deploy', 'unicorn:reload'



