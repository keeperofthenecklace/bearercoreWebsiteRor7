# Abstract base for read-only access to the SmartcheqWebsiteRor7 database.
# Bearer doesn't own these tables — never write through this connection.
class SmartcheqRecord < ApplicationRecord
  self.abstract_class = true

  establish_connection(
    adapter:  'postgresql',
    encoding: 'unicode',
    database: ENV.fetch('SMARTCHEQ_DB_NAME',     'smartcheq_prod_test'),
    username: ENV.fetch('SMARTCHEQ_DB_USERNAME',  ENV.fetch('DB_USERNAME', 'deploy')),
    password: ENV.fetch('SMARTCHEQ_DB_PASSWORD',  ENV.fetch('DB_PASSWORD', 'kwame1')),
    host:     ENV.fetch('SMARTCHEQ_DB_HOST',      ENV.fetch('DB_HOST', '127.0.0.1')),
    port:     ENV.fetch('SMARTCHEQ_DB_PORT',      ENV.fetch('DB_PORT', '5432')).to_i,
    pool:     3
  )
end
