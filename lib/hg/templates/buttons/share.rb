require 'types'

# facebook messenger share button object
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/share-button
class Share < Button
  attribute :type, Types::Strict::String('element_share')

  # TODO: how to require that the type is another struct?
  attribute :share_contents, Types::Strict::Hash.member(ShareTemplate)

  # https://developers.facebook.com/docs/messenger-platform/send-api-reference/generic-template
  # may only have up to one url button
  # TODO: implement this after generic template struct is created
  class ShareTemplate
    attribute :type, Types::Strict::String('generic')
  end
end

