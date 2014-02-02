set :rvm_ruby_string, :local # use the same ruby as used locally for deployment

set :application, 'cloud-status'
set :repo_url, 'git@github.com:datapipe/cloud-status.git'

set :default_stage, 'staging'
set :stages, %w(staging production)

ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :deploy_to, '/srv/app'
set :scm, :git

set :format, :pretty
set :log_level, :debug
set :pty, true

# set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :keep_releases, 10


namespace :thin do
  desc 'Start the Thin processes'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        execute :bundle, "exec thin start -O -C config/thin/#{fetch(:rails_env)}.yml"
      end
    end
  end

  desc 'Stop the Thin processes'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        execute :bundle, "exec thin stop -O -C config/thin/#{fetch(:rails_env)}.yml"
      end
    end
  end

  desc 'Restart the Thin processes'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        execute :bundle, "exec thin restart -O -C config/thin/#{fetch(:rails_env)}.yml"
      end
    end
  end
end

after 'deploy', 'thin:restart'

