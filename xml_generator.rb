require 'json'
require 'nokogiri'
require 'zip'

require_relative 'url_utils'
require_relative 'redis_keys'
require_relative 'sidekiq'

class XmlGenerator
  include RedisKeys
  include UrlUtils

  RECORDS_PER_FILE = 50_000
  SIZE_PER_FILE = 10_485_760 # 10 MB


  def initialize(url)
    @url = url
    @data = data
    self
  end

  def data
    index = 0
    results = [{
                 'loc' => @url.to_s,
                 'priority' => 1.0
               }]
    begin
      res = $redis.sscan children_key(@url), index #, match: match
      res[1].each do |u|
        results << JSON.parse(u)
      end
      index = res[0]
    end while index != '0'
    results
  end

  def to_xml(data = @data)
    Nokogiri::XML::Builder.new do |xml|
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
    end.to_xml
  end

  def to_zip(path)
    xmls = sitemaps

    files = []

    Zip::File.open(path, Zip::File::CREATE) do |zip|
      if xmls.length == 1
        name = 'sitemap.xml'
        files << tempfile(name, xmls[0])
        add_file(files.last, name, zip)
      else
        names =
          xmls.each_with_index.map do |xml, i|
            name = "sitemap#{i + 1}.xml"
            files << tempfile(name, xml)
            add_file(files.last, name, zip)
            name
          end

        name = 'sitemapindex.xml'
        file = tempfile(name, sitemap_index(names))
        add_file(file, name, zip)
      end
    end

    files.map(&:unlink)
  end

  def add_file(file, name, zip)
    zip.remove(name) if zip.instance_variable_get(:@entry_set).include?(name)
    zip.add(name, file.path)
  end

  def sitemaps
    xmls = []

    while @data && @data.length > 0
      xml, next_index = next_sitemap(@data)
      xmls << xml
      @data = @data[next_index..-1]
    end

    xmls
  end

  def next_sitemap(data)
    urls = data[0...RECORDS_PER_FILE]
    xml = to_xml(urls)

    if xml.size <= SIZE_PER_FILE
      [xml, urls.length]
    else
      # Hope that it will fit to size
      index = (data.size.to_f * SIZE_PER_FILE * 0.95 / xml.size).to_i
      next_sitemap(data[0...index])
    end
  end

  def sitemap_index(names)
    Nokogiri::XML::Builder.new do |xml|
      xml.sitemapindex(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
        names.each do |n|
          xml.sitemap do
            xml.loc UrlUtils.escape_url(n)
          end
        end
      end
    end.to_xml
  end

  def tempfile(name, xml)
    file = Tempfile.new([name, '.xml'])
    begin
      file.write(xml)
    ensure
      file.close
    end
    file
  end
end

