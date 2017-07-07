require 'types'

# facebook messenger log in button object
# see https://developers.facebook.com/docs/messenger-platform/account-linking/unlink-account
class LogOut < Button
  attribute :type, Types::Strict::String('account_unlink')
end

