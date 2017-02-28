# Represents our connection to a Redis instance.
class Hg::Redis
  class << self
    # TODO: test
    def pool
      # TODO: Should enable setting connection pool size/timeout/redis URL as config option on Hg
      @pool ||= ConnectionPool.new(size: ENV['REDIS_CONNECTION_POOL_SIZE'], timeout: 5) do
        ::Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
      end
    end

    # TODO: test
    def execute(&block)
      pool.with do |conn|
        yield(conn)
      end
    end
  end
end
