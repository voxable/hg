module Hg
  class PostbackWorker
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
      raw_postback = Hg::Queues::Messenger::PostbackQueue
                  .new(user_id: user_id, namespace: redis_namespace)
                  .pop

      # Do nothing if no postback available. This could be due to multiple execution on the part of Sidekiq.
      # This ensures idempotence.
      return nil if raw_postback.empty?

      # Instantiate a postback object
      postback = Facebook::Messenger::Incoming::Postback.new(raw_postback)

      # Locate the class representing the bot.
      bot = Kernel.const_get(bot_class_name)
    end
  end
end
