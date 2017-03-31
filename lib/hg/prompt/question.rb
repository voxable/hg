module Hg
  class Prompt
    class Question
      # Store question message.
      # @api public
      attr_reader :message

      # Initialize a Question
      #
      # @api public
      def initialize(prompt, options = {})
        @prompt = prompt
      end

      # Call the question.
      #
      # @param [String] message
      #
      # @return [self]
      #
      # @api public
      def call(message, &block)
        @message = message
        block.call(self) if block
        render
      end

      # Ask the question.
      #
      # @api private
      def render
        @prompt.print(render_question)
      end

      # Render question.
      #
      # @return [String]
      #
      # @api private
      def render_question
        @message
      end
    end
  end
end
