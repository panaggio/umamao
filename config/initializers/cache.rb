# Monkey patch to prevent cache keys from getting frozen on retrieval.
# Freezing them screws up with MongoMapper:
# https://groups.google.com/forum/#!msg/mongomapper/duH3So9LXkA/u9sLx8JdTukJ
class ActiveSupport::Cache::Entry
  # Get the value stored in the cache.
  def value
    if @value
      compressed? ? Marshal.load(Zlib::Inflate.inflate(@value)) : @value
    end
  end
end
