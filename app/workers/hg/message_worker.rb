# Handles processing messages.
module Hg
  class MessageWorker
    include Sidekiq::Worker

    def perform(user_id, redis_namespace)
      # Retrieve the latest message for this user
      message = Hg::MessageStore.fetch_message_for_user(user_id, redis_namespace)

    end
  end
end
