# Represents an inbound request to a bot. Contains all relevant request information:
#
# * `user` - The user making the request.
# * `message` - The original message object from the bot's platform, converted to a `Hashie::Mash`.
# * `action` - The name of the action requested.
# * `intent` - The name of the intent requested.
# * `parameters` - Any parsed parameters (entities) for this request.
#
# A request is a `Hashie::Mash`, so properties can be accessed either as methods
# or hash attributes. Any additional info can be added to the request object:
#
#   request.processed_at = Time.now
#
# In order to check for valid attributes, a request must always be instantiated
# with a hash with symbolized keys, with all required values present:
#
#   Hg::Request.new({
#     action: 'searchSchedule',
#     intent: 'searchSchedule',
#     message: message,
#     user: user,
#     parameters: {
#       artist_name: 'Father John Misty'
#     }
#   })
class Hg::Request < Hashie::Mash
  # All required attributes for a request
  REQUIRED_ATTRS = [:action, :intent, :message, :user, :parameters]

  def initialize(attributes = {})
    REQUIRED_ATTRS.each do |attribute|
      raise ArgumentError.new("#{attribute} is required") unless attributes.has_key?(attribute)
    end
  end
end
