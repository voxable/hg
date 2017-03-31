module Hg
  class Prompt
    class Answer
      attr_accessor :text

      def initialize(text, options = {})
        @text = text.strip
        @user = options.fetch(:user)

        clear_dialog_handler_for_user!
      end

      private

      # TODO: This should be a message on User (we need a User module)
      def clear_dialog_handler_for_user!(options = {})
        # Is this the best way to clear these out?
        @user.update_context(
          dialog_handler:    nil,
          dialog_controller: nil
        )
      end
    end
  end
end
