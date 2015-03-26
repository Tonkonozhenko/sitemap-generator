require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'
require 'slim'
require 'dotenv'
require 'uri'

require_relative 'parser_worker'
require_relative 'xml_generator'
require_relative 'url_utils'

class SitemapApp < Sinatra::Base
  include UrlUtils

  register Sinatra::Reloader

  get '/' do
    slim :index
  end

  post '/' do
    # TODO need url regexp
    domain = normalize_domain(params[:domain])
    ParserWorker.perform_async(domain)
    # TODO return something
  end

  get '/find' do
    domain = normalize_domain(params[:domain])
    data = XmlGenerator.new(domain).as_json
    json data
    # TODO generate xml
    # nokogiri do |xml|
    #   xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
    #     xml.url do
    #
    #     end
    #   end
    # end
  end
end