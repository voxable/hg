# Handles processing messages.
module Hg
  class MessageWorker
    include Sidekiq::Worker
    # TODO: Make number of retries configurable.
    sidekiq_options retry: 1

    def perform(user_id, redis_namespace, bot_class_name)
      # Retrieve the latest message for this user
      message = Hg::Queues::Messenger::MessageQueue
                  .new(user_id: user_id, namespace: redis_namespace)
                  .pop

      # Do nothing if no message available. This could be due to multiple execution on the part of Sidekiq.
      # This ensures idempotence.
      return nil if message.empty?

      # Fetch the User representing the message's sender
      bot = Kernel.const_get(bot_class_name)
      user = bot.user_class.find_or_create_by(facebook_psid: user_id)

      # Send the message to API.ai for NLU
      nlu_response = ApiAiClient.new(user.api_ai_session_id).query(message.message.text)

      # Build a request object.
      request = Hg::Request.new({
        user: user,
        message: message,
        intent: nlu_response.intent,
        action: nlu_response.action,
        parameters: nlu_response.parameters
      })

      # Send the request to the bot's router.
      bot.router.handle(request)
    end
  end
end
