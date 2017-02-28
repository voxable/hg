require_relative 'redis'

# Enables temporary storage of an ordered list of unprocessed messages for a user.
class Hg::MessageStore
  class << self
    MESSAGES_QUEUE_KEY = 'messages'

    # TODO: test
    # Store a message for a user.
    #
    # @param user_id [String] The ID of a bot user on a particular platform.
    # @param message [Hash] The message to store.
    # @param namespace [String] The redis namespace under which to store the message.
    def store_message_for_user(user_id, message, namespace)
      key = message_key(user_id, namespace)

      Hg::Redis.execute do |conn|
        conn.rpush(key, message.messaging.to_json)
      end
    end

    # TODO: test
    # Retrieve the latest message for a user.
    #
    # @param user_id [String] The ID of a bot user on a particular platform.
    # @param message [Hash] The message to store.
    # @param namespace [String] The redis namespace under which to store the message.
    #
    # @return [Hashie::Mash] The stored message.
    def fetch_message_for_user(user_id, namespace)
      key = message_key(user_id, namespace)

      message = Hg::Redis.execute do |conn|
        if message_json = conn.rpop(key)
          JSON.parse(message_json)
        else
          {}
        end
      end

      return Hashie::Mash.new(message)
    end

    private

      # Generate a message queue key.
      #
      # @param user_id [String] The ID of a bot user on a particular platform.
      # @param message [Hash] The message to store.
      # @param namespace [String] The redis namespace under which to store the message.
      #
      # @return [String] The message queue key.
      def message_key(user_id, namespace)
        "#{namespace}:users:#{user_id}:#{MESSAGES_QUEUE_KEY}"
      end
  end
end
