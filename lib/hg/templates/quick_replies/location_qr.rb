# facebook messenger location quick reply template
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/quick-replies
class LocationQuickReply < Dry::Struct

  attribute :content_type, Types::Strict::String('location')
end
