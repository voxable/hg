require 'facebook/messenger'
require 'fuzzy_match'
require 'interactor/rails'
require 'hashie/mash'
require 'sidekiq'
require 'api-ai-ruby'

module Hg
  require 'hg/engine'
  
  # TODO: Move to Bot itself, default to User.
  # The class representing bot users.
  mattr_accessor :user_class
end
