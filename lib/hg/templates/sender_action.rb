require 'types'

# Facebook Messenger object for sender actions
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/sender-actions
class SenderActions < Dry::Struct
  attribute :sender_action, Type::SenderActions
end
