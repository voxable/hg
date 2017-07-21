require 'types'

# facebook messenger quick reply template
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/quick-replies
class QuickReply < Dry::Struct

  attribute :content_type, Types::ContentType
  attribute :quick_replies, Types::Strict::Array
                        .member(
                          QuickReply::TextQuickReply || QuickReply::LocationQuickReply
                        )
                        .constrained(size: 1..11)
end
