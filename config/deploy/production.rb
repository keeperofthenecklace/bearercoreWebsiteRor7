server '159.223.136.209', user: 'deploy', roles: %w{app db web}

set :default_env, {
  'BASE_URL'  => 'https://www.bearercore.com',
  'RAILS_ENV' => 'production'
}
