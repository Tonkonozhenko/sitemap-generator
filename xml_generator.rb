require 'json'
require_relative 'sidekiq'
require_relative 'redis_keys'

class XmlGenerator
  include RedisKeys

  def initialize(url)
    @counter = 0
    @data = data(url)
    self
  end

  def data(url)
    {
      url: url,
      children: children(url)
    }
  end

  def children(url)
    children = $redis.lrange(children_key(url), 0, -1)
    children.delete(url)
    children.map { |u| data(u) }
  end

  def as_json
    @data
  end

  def to_json
    @data.to_json
  end
end

