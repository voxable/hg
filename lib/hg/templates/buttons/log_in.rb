require 'types'

# facebook messenger log in button object
# see https://developers.facebook.com/docs/messenger-platform/account-linking/link-account
class LogIn < Button
  attribute :type, Types::Strict::String('account_link')
  attribute :url, Types::Url
end

