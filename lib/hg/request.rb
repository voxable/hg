# Represents an inbound request to a bot. Contains all relevant request information:
#
# * `user` - The user making the request.
# * `message` - The original message object from the bot's platform, converted to a `Hashie::Mash`.
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

  def initialize(action:, intent: nil, message: nil, user:, parameters: {}, response: nil)
    @action = action
    @intent = intent
    @message = message
    @user = user
    @parameters = parameters
    @response = response
  end
end
