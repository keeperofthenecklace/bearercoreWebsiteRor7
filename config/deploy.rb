# config/deploy.rb
#
# Capistrano deployment configuration for bearerCORE

lock "~> 3.19.2"

set :application, "bearercore"

# Repository configuration
set :repo_url, "git@github.com:keeperofthenecklace/bearercoreWebsiteRor7.git"

set :branch, "main"
set :deploy_to, "/home/deploy/#{fetch :application}"

# Ruby & rbenv configuration
set :rbenv_type, :user
set :rbenv_ruby, "3.3.6"
set :rbenv_map_bins, %w[rake gem bundle ruby rails]

# App URLs
set :default_env, {
  "BASE_URL"  => "https://www.bearercore.com",
  "RAILS_ENV" => "production"
}

# Linked files & directories
append :linked_files, "config/database.yml", "config/master.key", ".env"

append :linked_dirs,
       "log",
       "tmp/pids",
       "tmp/cache",
       "tmp/sockets",
       "vendor",
       "public/system",
       "storage",
       "app/assets/builds"

set :keep_releases, 3
set :passenger_restart_with_touch, true
set :bundle_jobs, 2

# ═══════════════════════════════════════════════════════════════════════════════
# DEPLOY TASKS
# ═══════════════════════════════════════════════════════════════════════════════

namespace :deploy do
  desc "Ensure bundler is configured correctly"
  task :prepare_bundle do
    on roles(:app) do
      within release_path do
        execute :bundle, "config unset deployment"
      end
    end
  end

  before "deploy:assets:precompile", "deploy:prepare_bundle"

  desc "Restart application"
  task :restart do
    on roles(:app) do
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end

  after :publishing, "deploy:restart"
  after :finishing, "deploy:cleanup"
end
