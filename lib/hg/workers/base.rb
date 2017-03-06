module Hg
  module Workers
    class Base
      include Sidekiq::Worker

      private

        # Pop a message from the passed queue.
        #
        # @param queue_class [Class] The class representing the queue from which
        #   to pop
        # @param user_id [String, Integer] The ID representing the user on this platform
        # @param namespace [String] The redis namespace under which the message to
        #   process is nested.
        #
        # @return [Hash] The raw, popped message.
        def pop_from_queue(queue_class, user_id:, namespace:)
          queue_class
            .new(user_id: user_id, namespace: namespace)
            .pop
        end

        # Find the appropriate user for this request.
        #
        # @param bot [Class] The class representing the bot in question.
        # @param user_id [String, Integer] The id of the user to fetch.
        #
        # @return [Class] The user that initiated the request.
        def find_bot_user(bot, user_id)
          bot.user_class.find_or_create_by(facebook_psid: user_id)
        end
    end
  end
end
