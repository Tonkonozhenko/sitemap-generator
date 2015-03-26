module UrlUtils
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
    normalize_path(URI.join(url, '/'))
  end
end