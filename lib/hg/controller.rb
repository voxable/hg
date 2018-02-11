# frozen_string_literal: true

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
  # `handler` in place of `action` in the method name. If the filter chain should
  # be halted, you must call the `halt` method.
  #
  #   class BotController < Hg::Controller
  #     before_handler :require_login
  #
  #     private
  #
  #       def require_login
  #         unless user.logged_in?
  #           respond 'You must be logged in to access this.'
  #           respond_with OrderBot::Chunks::Login and halt
  #         end
  #       end
  #  end
  #
  # TODO: Should this object be Controllers::Base?
  class Controller
    # Create a new instance of Controller.
    #
    # @option request [Hash] The incoming request.
    # @option router [Hg::Router] The router that handled the request.
    # @option handler_name [String] The name of the handler to be executed.
    def initialize(request: {}, router: nil, handler_name: nil)
      @request = request
      # TODO: Test that params or parameters works, here.
      @params = ActiveSupport::HashWithIndifferentAccess.new(request.parameters || request.params)
      @user = request.user
      @performed = false
      @router = router
      @handler_name = handler_name.to_s
    end

    attr_accessor :params
    alias_method :parameters, :params
    attr_accessor :request
    attr_accessor :user

    # Necessary for compatibility with `ActiveSupport::Callbacks` `only` and
    # `except` options
    attr_accessor :handler_name
    alias_method :action_name, :handler_name

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

    # Will be set to `true` by calling `halt`, thus halting the execution
    # of the filter chain.
    #
    # @see AbstractController::Base#performed?
    # @see #halt
    def performed?
      @performed
    end

    # Halt the execution of the filter chain.
    def halt
      # TODO: This is a gross hack. You're supposed to throw(:abort).
      @performed = true
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

    # Generate a context based on merging the params into the user's current context.
    #
    # @return [ActiveSupport::HashWithIndifferentAccess] The merged context.
    def merged_context
      ActiveSupport::HashWithIndifferentAccess
        .new((user.context_hash || {})
        .merge(params))
    end

    # Show a typing indicator to the user.
    def show_typing
      Facebook::Messenger::Bot.deliver({
        recipient: {id: user.facebook_psid},
        sender_action: 'typing_on'
      }, access_token: ENV['FB_ACCESS_TOKEN'])
    end

    def flash(message)
      message = message.sample if message.respond_to?(:sample)
      respond(message)
      show_typing
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
        response = Facebook::Messenger::Bot.deliver(
          {
            recipient: {
              id: user.facebook_psid
            },
            message: {
              text: message_text
            }
          }, access_token: ENV['FB_ACCESS_TOKEN']
        )

        # Send to Chatbase
        if ENV['CHATBASE_API_KEY']
          ChatbaseAPIClient.new.send_bot_message(message_text, response)
        end
      # If we're attempting to deliver a chunk...
      elsif args.first.is_a?(Class)
        # ....deliver the chunk
        chunk_class = args[0]
        chunk_context = args[1] || {}

        chunk_class.new(recipient: user.facebook_psid, context: chunk_context).deliver
      end
    end
    alias_method :reply, :respond
    alias_method :ask, :respond
    alias_method :respond_with, :respond

    # TODO: High - document and test
    def redirect_to(payload = {})
      request.action = payload[:action]
      request.intent = payload[:action] || payload[:intent]
      request.route  = payload[:route]
      # TODO: Seems like we need a method for fetching params value.
      request.parameters = payload[:parameters] || payload[:params]

      @router.handle(request)
    end

    # Expose the Sidekiq logger to the controller.
    def logger
      Sidekiq::Logging.logger
    end

    def t(*args)
      I18n.t(*args)
    end
  end
end
