require 'facebook/messenger'
require 'fuzzy_match'
require 'interactor/rails'
require 'hashie/mash'

require 'hg/version'
require 'hg/engine'
require 'hg/action'
require 'hg/bot'
require 'hg/chunk'
require 'hg/controller'
require 'hg/message_store'
require 'hg/router'

# Ensure Hashie logs to Rails logger
Hashie.logger = Rails.logger

module Hg
  # TODO: Move to Bot itself, default to User.
  # The class representing bot users.
  mattr_accessor :user_class
end
