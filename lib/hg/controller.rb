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
  class Controller
    # Create a new instance of Controller.
    #
    # @param request [Hash] The incoming request.
    def initialize(request: {})
      @request = request
      self.params = request[:parameters] || request[:params]
      @user = request[:user]
    end

    attr_accessor :params
    alias_method :parameters, :params

    # Store a new value for the params object.
    #
    # @param new_params [Hash] The parameters for the request.
    def params=(new_params)
      @params = Hashie::Mash.new(new_params)
    end

    attr_accessor :request
    attr_accessor :user

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
        # ...deliver the method.

        message_text = args.first

        # TODO: Add this as a method to Bot.
        Facebook::Messenger::Bot.deliver({
          recipient: {
            id: user.facebook_psid
          },
          message: {
            text: message_text
          }
        }, access_token: ENV['ACCESS_TOKEN'])
      end
    end
  end
end