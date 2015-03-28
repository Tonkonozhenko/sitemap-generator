require 'open-uri'
require 'nokogiri'
require 'uri'
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
      visit!(url)
      add_to_parent(url, parent)
      parse_page_links(level, url, parent) if level < LEVEL
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
      if url.to_s.index(@domain.to_s) == 0 # Check if url is absolute
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
  def add_to_parent(link, parent)
    if parent && link.to_s != parent.to_s
      $redis.sadd(children_key(parent), link)
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

  def parse_page_links(level, url, parent)
    # Can not parse habr without user agent
    doc = Nokogiri::HTML(open(url, HEADERS))

    doc.css('a').each do |link|
      link = normalize(link.attr('href'))
      self.class.perform_async(link, parent, level + 1) if link && valid?(link)
    end
  end
end