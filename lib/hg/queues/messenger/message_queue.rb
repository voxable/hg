require 'hg/redis'

# Enables temporary storage of an ordered list of unprocessed messages for a user.
module Hg
  module Queues
    module Messenger
      class MessageQueue < Hg::Queues::Queue
        MESSAGES_QUEUE_KEY_PORTION = 'messenger:messages'

        def initialize(user_id: nil, namespace: nil)
          key = message_key(user_id, namespace)

          super(key)
        end

        private

          # Generate a message queue key.
          #
          # @param user_id [String] The ID of a bot user on a particular platform.
          # @param namespace [String] The redis namespace under which to store the message.
          #
          # @return [String] The message queue key.
          def message_key(user_id, namespace)
            "#{namespace}:users:#{user_id}:#{MESSAGES_QUEUE_KEY_PORTION}"
          end
      end
    end
  end
end
