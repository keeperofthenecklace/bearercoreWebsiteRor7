# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require "capistrano/rbenv"
require "capistrano/rails"
require "capistrano/passenger"

# tailwindcss-rails wires tailwindcss:build into assets:precompile automatically.
# This hook makes it explicit and ensures the build runs before Sprockets compiles.
namespace :deploy do
  before "deploy:assets:precompile", :build_tailwind do
    on roles(:web) do
      within release_path do
        with rails_env: fetch(:rails_env, "production") do
          execute :bundle, "exec rails tailwindcss:build"
        end
      end
    end
  end
end

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }

set :rbenv_type, :user
set :rbenv_ruby, '3.3.6'
