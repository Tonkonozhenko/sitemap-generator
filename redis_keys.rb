module RedisKeys
  private
  def children_key(url)
    "children:#{url}"
  end

  def visited_key(url)
    "visited:#{url}"
  end
end
