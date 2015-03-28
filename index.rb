require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'
require 'slim'

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
    domain = normalize_domain(params[:domain])
    if domain
      ParserWorker.perform_async(domain)
    else
      json status: error
    end
  end

  get '/find' do
    domain = normalize_domain(params[:domain])
    data = XmlGenerator.new(domain).as_json

    nokogiri do |xml|
      xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
        data.each do |d|
          xml.url do
            xml.loc(UrlUtils.escape_url(d['loc']))
            xml.lastmod(d['lastmod']) if d['lastmod']
            xml.changefreq(d['changefreq']) if d['changefreq']
            xml.priority(d['priority']) if d['priority']
          end
        end
      end
    end
  end
end