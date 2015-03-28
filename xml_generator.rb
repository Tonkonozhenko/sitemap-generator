require 'json'
require_relative 'sidekiq'
require_relative 'redis_keys'

class XmlGenerator
  include RedisKeys

  def initialize(url)
    @data = data(url)
    self
  end

  def data(url)
    index = 0
    results = [{
                 'loc' => url.to_s,
                 'priority' => 1.0
               }]
    begin
      res = $redis.sscan children_key(url), index#, match: match
      res[1].each do |u|
        results << JSON.parse(u)
      end
      index = res[0]
    end while index != '0'
    results
  end

  def as_json
    @data
  end

  def to_json
    @data.to_json
  end
end

