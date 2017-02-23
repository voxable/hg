require 'facebook/messenger'
require 'fuzzy_match'
require 'interactor/rails'
require 'hashie/mash'

require 'hg/version'
require 'hg/action'
require 'hg/bot'
require 'hg/chunk'
require 'hg/engine'
require 'hg/router'

# Ensure Hashie logs to Rails logger
Hashie.logger = Rails.logger

module Hg
  # The root class for the bot.
  mattr_accessor :bot_class

  module_function

  # @return [Hashie::Mash] The routes map for the bot.
  def routes
    # Assume that a router has been defined.
    # TODO: Test that a router class has been defined on init.
    bot_class::Router.routes
  end
end
