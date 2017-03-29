module Hg
  # Handles processing postbacks. A postback is any structured request from
  # any platform (i.e. button and quick replies, which send hash payloads).
  class PostbackWorker < Workers::Base
    include Sidekiq::Worker
    # TODO: Make number of retries configurable.
    sidekiq_options retry: 1

    # Process an inbound postback.
    #
    # @param user_id [String, Integer] The ID representing the user on this platform
    # @param redis_namespace [String] The redis namespace under which the postback
    #   to process is nested.
    # @param bot_class_name [String] The string version of the bot's class name
    #
    # @return [void]
    def perform(user_id, redis_namespace, bot_class_name)
      # Retrieve the latest postback for this user
      raw_postback = pop_raw_postback(user_id, redis_namespace)

      # Do nothing if no postback available. This could be due to multiple
      # execution on the part of Sidekiq. This ensures idempotence. We loop
      # here to ensure that this worker attempts to drain the queue for
      # the user.
      while raw_postback != {}
        # Extract the payload from the postback.
        payload = Facebook::Messenger::Incoming::Postback.new(raw_postback).payload

        # Locate the class representing the bot.
        bot = Kernel.const_get(bot_class_name)

        # Fetch the User representing the message's sender
        # TODO: pass in a `user_id_field` to indicate how to find user in order to
        # make this platform agnostic
        user = find_bot_user(bot, user_id)

        # Build a request object.
        request = build_payload_request(payload, user)

        # Send the request to the bot's router.
        bot.router.handle(request)

        # Attempt to pop another postback from the queue for processing.
        raw_postback = fetch_raw_postback(user_id, redis_namespace)
      end
    end

    private

    # @return [Hash] The latest raw postback from this user's queue.
    def pop_raw_postback(user_id, redis_namespace)
      pop_from_queue(
        Hg::Queues::Messenger::PostbackQueue,
        user_id:   user_id,
        namespace: redis_namespace
      )
    end
  end
end
