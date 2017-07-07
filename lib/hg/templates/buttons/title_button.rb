require 'types'

# facebook messenger button object that has a title
# ie (not a share, buy or log in/out button)
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/message-buttons
class TitleButton < Dry::Struct

  attribute :title, Types::Strict::String.constrained(max_size:20)

end

