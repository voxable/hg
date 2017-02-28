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
      bot = Kernel.const_get(bot_class_name)
      user = bot.user_class.find_or_create_by_facebook_psid(user_id)

      # Send the message to API.ai for NLU
      api_ai_client = ApiAiClient.new(user.api_ai_session_id).query(message.text)

      # Build a request object.
      request = Hashie::Mash.new

      # Send the request to the bot's router.
      bot.router.handle(request)
    end
  end
end
