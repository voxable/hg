module Hg
  module Messenger
    class Answer < Hg::Prompt::Answer
      def initialize(message, options = {})
        super(message.text, options)
      end
    end
  end
end
