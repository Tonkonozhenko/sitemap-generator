require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'
require 'slim'
require 'better_errors'

require_relative 'parser_worker'
require_relative 'xml_generator'
require_relative 'url_utils'

class SitemapApp < Sinatra::Base
  include UrlUtils

  configure :development do
    register Sinatra::Reloader
    also_reload 'xml_generator.rb'

    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path('.', __FILE__)
  end

  get '/' do
    XmlGenerator.new('http://getbootstrap.com').to_zip(File.dirname(__FILE__) + '/public/schemas/getbootstrap.com.zip')

    @domains = $redis.keys('counter:*')
    if @domains.any?
      counters = $redis.mget($redis.keys('counter:*'))
      @domains = @domains.each_with_index.map do |e, i|
        url = e.split('counter:').last
        domain = normalize_domain(url)

        { url: url,
          finished: counters[i].to_i <= -1,
          download_link: "/schemas/#{domain.host}.zip" }
      end
    end

    slim :index
  end

  post '/' do
    domain = normalize_domain(params[:domain])
    ParserWorker.perform_async(domain) if domain
    redirect '/'
  end

  get '/find' do
    domain = normalize_domain(params[:domain])
    XmlGenerator.new(domain).to_xml
  end
end