require 'types'

# facebook messenger button object
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/message-buttons
class Button < Dry::Struct

  # TODO: support buy button
  # see https://developers.facebook.com/docs/messenger-platform/send-api-reference/buy-button
  attribute :type, Types::Strict::String.enum(
    'account_link',
    'account_unlink',
    'phone_number',
    'postback',
    'share',
    'web_url'
  )

end

