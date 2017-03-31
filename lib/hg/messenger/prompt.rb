module Hg
  module Messenger
    class Prompt < Hg::Prompt
      def initialize(options = {})
        messenger_prompt = Hg::Prompt::Outputs::MessengerOutput.new(user_id: options.fetch(:user_id))

        super(output: messenger_prompt)
      end
    end
  end
end
