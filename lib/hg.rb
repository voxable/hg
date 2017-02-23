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
  # Your code goes here...
end
