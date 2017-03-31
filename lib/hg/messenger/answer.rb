module Hg
  module Messenger
    class Answer < Hg::Prompt::Answer
      def initialize(message)
        super(message.text)
      end
    end
  end
end
