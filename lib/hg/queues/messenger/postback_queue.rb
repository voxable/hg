require 'hg/redis'

# Enables temporary storage of an ordered list of unprocessed postbacks for a user.
module Hg
  module Queues
    module Messenger
      class PostbackQueue < Hg::Queues::Queue
        POSTBACKS_QUEUE_KEY_PORTION = 'messenger:postbacks'

        def initialize(user_id: nil, namespace: nil)
          key = message_key(
            user_id: user_id,
            namespace: namespace,
            key_portion: POSTBACKS_QUEUE_KEY_PORTION
          )

          super(key)
        end
      end
    end
  end
end
