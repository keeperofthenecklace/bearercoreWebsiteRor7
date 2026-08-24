server '159.223.136.209', user: 'deploy', roles: %w{app db web}

set :default_env, {
  'BASE_URL'  => 'https://www.bearercore.com',
  'RAILS_ENV' => 'production',
  # Identity-authority (SmartcheqWebsiteRor7) API origin for browser claim POSTs.
  # Exported here so Passenger always loads it even if .env fails to load; the layout
  # meta tag + JS resolver provide belt-and-suspenders fallbacks to the same value.
  'SMARTCHEQ_BROWSER_API_BASE' => 'https://api.smartcheq.com'
}
