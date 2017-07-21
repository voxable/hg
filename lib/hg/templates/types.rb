require 'dry-struct'
require 'dry-types'

# dry-types
module Types
  include Dry::Types.module

  WebViewHeightRatio = Types::Strict::String.enum('compact', 'tall', 'full')
  Url = Types::Strict::String.constrained(format: %r{\Ahttps:\/\/.*/})
  ContentType = Types::Strict::String.enum('text', 'location')
end
