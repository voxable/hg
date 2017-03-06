# Whereas:
# * Messages must be processed in the order they are received.
# * We're using multiple Sidekiq workers executing in parallel to process messages.
# * Sidekiq jobs must be idempotent.
#
# ...be it resolved that we need a distributed FIFO queue for processing messages.
# Queue is that class. It uses a redis List as a storage mechanism.
#
# Since each platform may have several different types of messages that need their
# own processing (for example, postbacks vs regular messages in Messenger), a
# particular bot implementation may need several processing queues.
# TODO: test
module Hg
  module Queues
    class Queue
      # Create a new interface to a queue living in redis at `queue_key`.
      #
      # @param queue_key [String] The key at which the queue is stored in redis.
      #
      # @return [Hg::Queues::Queue]
      def initialize(queue_key)
        @key = queue_key
      end

      # Pop the oldest message off of the queue.
      #
      # @return [Hashie::Mash] The oldest message on the queue.
      def pop
        message = Hg::Redis.execute do |conn|
          if message_json = conn.lpop(@key)
            JSON.parse(message_json)
          else
            {}
          end
        end

        return Hashie::Mash.new(message)
      end

      # Push a message onto the queue.
      #
      # @param message [#to_json] The message to store on the queue.
      def push(message)
        Hg::Redis.execute do |conn|
          conn.rpush(@key, message.to_json)
        end
      end

      private

        # Generate a key for the queue in redis.
        #
        # @param user_id [String] The ID of a bot user on a particular platform.
        # @param namespace [String] The redis namespace under which to store the message.
        # @param key_portion [String] The portion of the queue representing this message queue.
        #
        # @return [String] The message queue key.
        def message_key(user_id:, namespace:, key_portion:)
          "#{namespace}:users:#{user_id}:#{key_portion}"
        end
    end
  end
end
