# Represents an inbound request to a bot. Contains all relevant request information:
#
# * `user` - The user making the request.
# * `message` - The original message object from the bot's platform, converted to a `Hashie::Mash`.
# * `action` - The name of the action requested.
# * `intent` - The name of the intent requested.
# * `parameters` - Any parsed parameters (entities) for this request.
class Hg::Request
  attr_accessor :action
  attr_accessor :intent
  attr_accessor :message
  attr_accessor :user
  attr_accessor :parameters

  def initialize(action:, intent: nil, message: nil, user:, parameters: {})
    @action = action
    @intent = intent
    @message = message
    @user = user
    @parameters = parameters
  end
end
