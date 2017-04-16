require 'facebook/messenger'
require 'fuzzy_match'
require 'hashie/mash'
require 'sidekiq'
require 'api-ai-ruby'

# TODO: List subordinate requires in their respective files.
require 'hg/engine'

module Hg
  # TODO: Move to Bot itself, default to User.
  # The class representing bot users.
  mattr_accessor :user_class
end
