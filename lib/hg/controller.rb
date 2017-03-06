module Hg
  # An Hg controller defines a number of handler functions for actions. These
  # are analogous to the concept of "controller actions" in Rails.
  #
  # ## Handlers
  #
  # Handler methods have access to the following objects:
  #
  # * `request`: The request passed along by the `Router`.
  # * `params`: The parameters passed along for this action by the `Router`.
  # * `user`: The user that sent the request.
  #
  # ## Filters
  #
  # You have access to [all of the same filters you're used to](http://guides.rubyonrails.org/action_controller_overview.html#filters)
  # from ActionController. They can either be accessed in their normal form, or with
  # `handler` in place of `action` in the method name:
  #
  #   class BotController < Hg::Controller
  #     before_handler :require_login
  #
  #     private
  #
  #       def require_login
  #         unless user.logged_in?
  #           respond 'You must be logged in to access this.'
  #           respond_with OrderBot::Chunks::Login
  #         end
  #       end
  #  end
  class Controller
    # Create a new instance of Controller.
    #
    # @param request [Hash] The incoming request.
    def initialize(request: {})
      @request = request
      self.params = ActiveSupport::HashWithIndifferentAccess.new(@request.parameters)
      @user = request.user
    end

    attr_accessor :params
    alias_method :parameters, :params
    attr_accessor :request
    attr_accessor :user

    # Call the action. Override this in a subclass to modify the
    # behavior around processing an action. This, and not `#process`,
    # is the intended way to override action dispatching.
    #
    # Notice that the first argument is the handler method to be dispatched
    # which is *not* necessarily the same as the action name.
    #
    # Providing this method allows us to use `AbstractController::Callbacks`
    def process_action(method_name, *args)
      # TODO: The run_callbacks shouldn't be here, but for some reason including
      # AbstractController::Callbacks isn't overriding this method.
      run_callbacks(:process_action) do
        send_action(method_name, *args)
      end
    end

    # Actually call the handler associated with the action. Override
    # this method if you wish to change how action handlers are called,
    # not to add additional behavior around it. For example, you would
    # override #send_action if you want to inject arguments into the
    # method.
    alias_method :send_action, :send

    # Used to ensure that filters are not terminated. Unlike in ActionController,
    # there is no response body to be set that would terminate the callback chain.
    #
    # @see AbstractController::Base#performed?
    def performed?
      false
    end

    # Enable use of Rails-style controller filters
    include AbstractController::Callbacks

    class << self
      # Since we call our actions 'handlers' (as the term action is part of the concept
      # of the bot's NLU), we need to alias all of the filter callbacks.
      alias_method :before_handler, :before_action
      alias_method :prepend_before_handler, :prepend_before_action
      alias_method :skip_before_handler, :skip_before_action
      alias_method :append_before_handler, :append_before_action
      alias_method :after_handler, :after_action
      alias_method :prepend_after_handler, :prepend_after_action
      alias_method :skip_after_handler, :skip_after_action
      alias_method :append_after_handler, :append_after_action
      alias_method :around_handler, :around_action
      alias_method :prepend_around_handler, :prepend_around_action
      alias_method :skip_around_handler, :skip_around_action
      alias_method :append_around_handler, :append_around_action
    end

    # Send a message back to the user. It's possible to either pass a string,
    # which will be delivered as a text message, or a chunk and its context:
    #
    #   respond Chunks::ConfirmBookingSuccess, {time: Time.now}
    #
    #   respond 'Sounds good!'
    # TODO: Document these params
    def respond(*args)
      # If we're attempting to send back a simple text message...
      if args.first.is_a?(String)
        # ...deliver the message.

        message_text = args.first

        # TODO: Add this as a method to Bot.
        Facebook::Messenger::Bot.deliver({
          recipient: {
            id: user.facebook_psid
          },
          message: {
            text: message_text
          }
        }, access_token: ENV['FB_ACCESS_TOKEN'])
      # If we're attempting to deliver a chunk...
      elsif args.first.is_a?(Class)
        # ....deliver the chunk
        chunk_class = args[0]
        chunk_options = args[1] || {}
        chunk_context = chunk_options[:context]

        chunk_class.new(recipient: user.facebook_psid, context: chunk_context).deliver
      end
    end
    alias_method :reply, :respond
    alias_method :respond_with, :respond
  end
end
