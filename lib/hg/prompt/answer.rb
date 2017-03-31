module Hg
  class Prompt
    class Answer
      attr_accessor :text

      def initialize(text)
        @text = text.strip
      end
    end
  end
end
