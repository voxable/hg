require 'types'

# facebook messenger quick reply template
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/quick-replies
class QuickReply < Dry::Struct

  attribute :content_type, Types::ContentType
end
