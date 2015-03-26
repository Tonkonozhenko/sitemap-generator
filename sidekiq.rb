require 'sidekiq'
require 'dotenv'

Dotenv.load!

hash = { host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: ENV['REDIS_DB'], password: ENV['REDIS_PASSWORD'] }
Sidekiq.configure_server do |config|
  config.redis = hash
end
Sidekiq.configure_client do |config|
  config.redis = hash
end

$redis = Sidekiq.redis { |conn| conn }