module Hg
  module Dialogflow
    module Fulfillment
      # TODO: High - document and test
      module Messenger
        class Responder
          #
          def initialize(request)
            @request = request
          end

          #
          def respond
            MapperChunk.new(recipient: @request.user.facebook_psid,
                            context: @request.fulfillment).deliver
          end
        end
      end
    end
  end
end
