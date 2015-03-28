require 'open-uri'
require 'rest-client'
require 'nokogiri'
require 'uri'
require 'json'

require_relative 'redis_keys'
require_relative 'sidekiq'
require_relative 'xml_generator'
require_relative 'url_utils'

LEVEL = ENV['LEVEL'].to_i

class ParserWorker
  HEADERS = { 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36' }

  include UrlUtils
  include RedisKeys
  include Sidekiq::Worker

  sidekiq_options backtrace: true

  def perform(url, parent = url, level = 1)
    url = normalize_path(url)
    get_domain(url)

    unless visited?(url)
      # Can not parse habr without user agent
      doc = download_page(url)

      if doc
        visit!(url)
        last_modified = Time.parse(doc.headers[:last_modified]).strftime('%Y-%m-%dT%H:%M:%S%:z') rescue nil
        add_to_parent(parent, url, last_modified)
        parse_page_links(doc.body, level, parent) if level < LEVEL
      end
    end
  end

  def download_page(url)
    begin
      RestClient.get(url.to_s, HEADERS)
    rescue RestClient::Exception => ex
      # ignore if page status code == 4**
      raise unless ex.http_code / 100 == 4
      nil
    end
  end

  private
  # Gets current domain
  def get_domain(url)
    @domain ||= normalize_domain(url)
  end

  # Normalizes relative and absolute urls
  def normalize(url)
    return if url.nil? || %w[mailto: javascript: skype:].any? { |e| url.index(e) == 0 }

    begin
      url.gsub!(/\s/, '')
      if url.index('//') == 0
        URI.parse(@domain.scheme + ':' + url)
      elsif url.to_s.index(@domain.to_s) == 0 # Check if url is absolute
        URI.parse(url)
      else
        @domain + url
      end
    rescue
      false
    end
  end

  # Checks if url belongs to current domain
  def valid?(url)
    url.host.nil? || (url.host == @domain.host && url.scheme == @domain.scheme)
  end

  # Saving results to redis
  def add_to_parent(parent, link, lastmod = nil, changefreq = nil, priority = nil)
    if parent && link.to_s != parent.to_s
      $redis.sadd(
        children_key(parent),
        { loc: link, lastmod: lastmod, changefreq: changefreq, priority: priority }.reject { |_, v| v.nil? }.to_json
      )
    end
  end

  # Check that page was visited
  def visited?(url)
    $redis.get(visited_key(url))
  end

  # Save to redis that page was visited
  def visit!(url)
    $redis.set(visited_key(url), true)
  end

  def parse_page_links(doc, level, parent)
    Nokogiri::HTML(doc).css('a').each do |link|
      link = normalize(link.attr('href'))
      self.class.perform_async(link, parent, level + 1) if link && valid?(link)
    end
  end
end