module Hg
  class Prompt
    module Outputs
      class MessengerOutput
        def initialize(options = {})
          @recipient_facebook_psid = options.fetch(:user_id)
        end

        def print(message)
          # TODO: Add this as a method to Bot.
          Facebook::Messenger::Bot.deliver(
            {
              recipient: {
                id: @recipient_facebook_psid
               },
               message: {
                 text: message
               }
            }, access_token: ENV['FB_ACCESS_TOKEN']
          )
        end
      end
    end
  end
end
