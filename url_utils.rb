require 'cgi'

module UrlUtils
  DOMAIN_REGEXP = /\A(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})/
  REPLACEMENTS_ORIGINAL = %w[& ' " > <]
  REPLACEMENTS_NEW = %w[&amp; &apos; &quot; &gt; &lt;]

  extend self

  def normalize_path(url)
    unless url.is_a?(URI::HTTP)
      url.gsub!(/\s/, '')
      url = URI.parse(url)
    end
    url.fragment = nil
    url.path = '' if url.path == '/'
    url
  end

  def normalize_domain(url)
    url = 'http://' + url unless url.to_s.index('http') == 0
    domain = normalize_path(URI.join(url, '/'))
    begin
      domain if domain.to_s.match(DOMAIN_REGEXP)
    rescue
      nil
    end
  end

  def escape_url(url)
    new_url = url
    REPLACEMENTS_ORIGINAL.each_with_index do |char, i|
      new_url.gsub!(char, REPLACEMENTS_NEW[i])
    end
    new_url
  end
end