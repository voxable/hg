require 'types'

# facebook messenger text quick reply template
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/quick-replies
class TextQuickReply < QuickReply

  attribute :content_type, Types::Strict::String('text')
  # Max FBM title length of 20
  attribute :title, Types::Strict::String.constrained(max_size:20)
  # Max FBM payload length of 1000
  attribute :payload, Types::Strict::String.constrained(max_length: 1000)
  attribute :image_url, Types::Url.optional
end
