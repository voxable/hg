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
    end
  end
end
