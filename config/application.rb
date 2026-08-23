require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# dotenv-rails does not reliably auto-load .env under Passenger in production, so
# ENV vars from shared/.env (Capistrano-linked) come back nil in the running app.
# Load it explicitly at boot so SMARTCHEQ_API_BASE / SMARTCHEQ_BROWSER_API_BASE /
# SMARTCHEQ_DB_* etc. are populated. Dotenv.load is non-destructive (never
# overwrites an already-set ENV var) and silently no-ops if the file is absent.
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))

module Bearercore
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
