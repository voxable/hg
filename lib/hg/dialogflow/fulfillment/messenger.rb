module Hg
  module Dialogflow
    module Fulfillment
      # TODO: High - document and test
      class Messenger
        #
        def initialize(bot, request)
          @bot = bot
          @request = request
        end

        #
        def respond
          @request
          @bot
        end
      end
    end
  end
end
