ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Runs BEFORE rails/test_help, which connects and may purge + reload the test
# schema; fixtures also DELETE and reload whole tables. 127.0.0.1:5432 is the
# SSH tunnel to the production Postgres server (the test: block's database lives
# there). Refuse unless the test DB is a disposable local one, e.g.
#   DATABASE_URL=postgres://deploy@127.0.0.1:55432/bearercore_ci_test
db = ActiveRecord::Base.connection_db_config.configuration_hash
if db[:database].to_s.match?(/prod/i) || db[:port].to_i == 5432
  abort "Refusing to run tests against #{db[:database]} on port #{db[:port]} " \
        "(the production tunnel). Point DATABASE_URL at a disposable database."
end

require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
