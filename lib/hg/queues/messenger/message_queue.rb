require 'hg/redis'

# Enables temporary storage of an ordered list of unprocessed messages for a user.
module Hg
  module Queues
    module Messenger
      class MessageQueue < Hg::Queues::Queue
        MESSAGES_QUEUE_KEY_PORTION = 'messenger:messages'

        def initialize(user_id: nil, namespace: nil)
          key = message_key(
            user_id: user_id,
            namespace: namespace,
            key_portion: MESSAGES_QUEUE_KEY_PORTION
          )

          super(key)
        end
      end
    end
  end
end
