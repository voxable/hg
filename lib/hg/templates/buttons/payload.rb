require 'types'

# facebook messenger postback button object
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/postback-button
class Payload < TitleButton
  attribute :type, Types::Strict::String('postback')
  attribute :payload, Types::Strict::String.constrained(max_length: 1000)
end

