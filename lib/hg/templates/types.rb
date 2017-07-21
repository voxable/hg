require 'dry-struct'
require 'dry-types'

# dry-types
module Types
  include Dry::Types.module

  WebViewHeightRatio = Types::Strict::String.enum('compact', 'tall', 'full')
  Url = Types::Strict::String.constrained(format: %r{\Ahttps:\/\/.*/})
  ContentType = Types::Strict::String.enum('text', 'location')
  SenderAction = Types::Strict::String.enum('mark_seen', 'typing_on', 'typing_off')
end
