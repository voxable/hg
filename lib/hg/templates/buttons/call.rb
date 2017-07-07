require 'types'

# facebook messenger call button object
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/call-button
class Call < TitleButton
  attribute :type, Types::Strict::String('phone_number')
  # https://stackoverflow.com/a/3350566/5831076
  # possible phone number length is 7-15 characters
  attribute :payload, Types::Strict::String.constrained(format: /\+\d{7,15}/)

end

