require 'types'

# facebook messenger url button object
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/url-button
class Url < TitleButton
  attribute :type, Types::Strict::String('web_url')
  # must use https
  attribute :url, Types::Url

  attribute :webview_height_ratio, Types::WebViewHeightRatio.optional

  # TODO: support messenger extensions ?
  # see https://developers.facebook.com/docs/messenger-platform/webview/extensions

end

