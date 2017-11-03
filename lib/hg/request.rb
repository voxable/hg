# Represents an inbound request to a bot. Contains all relevant request information:
#
# * `user` - The user making the request.
# * `message` - The original message object from the bot's platform.
# * `action` - The name of the action requested.
# * `intent` - The name of the intent requested.
# * `parameters` - Any parsed parameters (entities) for this request.
class Hg::Request
  # The action name
  attr_accessor :action
  # The intent name
  attr_accessor :intent
  # The original user message
  attr_accessor :message
  # The user that made the request
  attr_accessor :user
  # The request parameters
  attr_accessor :parameters
  alias_method :params, :parameters
  # The response suggested by the NLU
  attr_accessor :response
  # An (optional) specified route for the request. Used for prompts.
  attr_accessor :route

  # TODO: Use dry-initializer
  def initialize(options = {})
    @action     = options.fetch(:action)
    @user       = options.fetch(:user)
    @intent     = options.fetch(:intent) { nil }
    @message    = options.fetch(:message) { nil }
    @parameters = options.fetch(:parameters) { {} }
    @response   = options.fetch(:response) { nil }
    @route      = options.fetch(:route) { nil }
  end
end
