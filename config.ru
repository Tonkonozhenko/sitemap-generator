require 'sidekiq/web'
require_relative 'index'
run Rack::URLMap.new('/' => SitemapApp, '/sidekiq' => Sidekiq::Web)