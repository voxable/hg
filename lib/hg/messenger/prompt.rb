module Hg
  module Messenger
    class Prompt < Hg::Prompt
      def initialize(options = {})
        user = options.fetch(:user)
        messenger_prompt = Hg::Prompt::Outputs::MessengerOutput.new(user_id: user.facebook_psid)

        super(options.merge(output: messenger_prompt, user: user))
      end
    end
  end
end
