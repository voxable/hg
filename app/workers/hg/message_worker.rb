# Handles processing messages.
module Hg
  class MessageWorker
    include Sidekiq::Worker

    def perform(user_id, redis_namespace, bot_class_name)
      # Retrieve the latest message for this user
      message = Hg::MessageStore.fetch_message_for_user(user_id, redis_namespace)

      # Do nothing if no message available. This could be due to multiple execution on the part of Sidekiq.
      return nil if message.empty?

      # Fetch the User representing the message's sender
      bot_class = Kernel.const_get(bot_class_name)
      bot_class.user_class.find_or_create_by_facebook_psid(user_id)
    end
  end
end
