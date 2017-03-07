module Hg
  # Handles processing messages. A message is any inbound, freeform text from
  # any platform.
  class MessageWorker < Workers::Base
    # TODO: Make number of retries configurable.
    sidekiq_options retry: 1

    # Process an inbound message.
    #
    # @param user_id [String, Integer] The ID representing the user on this platform
    # @param redis_namespace [String] The redis namespace under which the message to
    #   process is nested.
    # @param bot_class_name [String] The string version of the bot's class name
    #
    # @return [void]
    def perform(user_id, redis_namespace, bot_class_name)
      # Retrieve the latest message for this user.
      raw_message = pop_from_queue(
        Hg::Queues::Messenger::MessageQueue,
        user_id: user_id,
        namespace: redis_namespace
      )

      # Do nothing if no message available. This could be due to multiple execution
      # on the part of Sidekiq. This ensures idempotence.
      return nil if raw_message.empty?

      # Instantiate a message object with the raw message from the queue.
      message = Facebook::Messenger::Incoming::Message.new(raw_message)

      # Locate the class representing the bot.
      bot = Kernel.const_get(bot_class_name)

      # Fetch the User representing the message's sender.
      # TODO: pass in a `user_id_field` to indicate how to find user in order to
      # make this platform agnostic
      user = find_bot_user(bot, user_id)

      # If the message is a quick reply...
      if payload = message.quick_reply
        # ...build a request object from the payload.
        request = build_payload_request(payload, user)
      # If the message is text...
      else
        # ...send the message to API.ai for NLU.
        nlu_response = ApiAiClient.new(user.api_ai_session_id).query(message.text)

        # Build a request object.
        request = Hg::Request.new({
          user: user,
          message: message,
          intent: nlu_response[:intent],
          action: nlu_response[:action],
          parameters: nlu_response[:parameters]
        })
      end

      # Send the request to the bot's router.
      bot.router.handle(request)
    end
  end
end
