# Handles processing messages.
module Hg
  class MessageWorker
    include Sidekiq::Worker

    def perform(user_id)

    end
  end
end
