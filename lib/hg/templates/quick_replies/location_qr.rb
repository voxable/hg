require 'types'

# facebook messenger location quick reply template
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/quick-replies
class LocationQuickReply < QuickReply
  attribute :content_type, Types::ContentType('text')
end
