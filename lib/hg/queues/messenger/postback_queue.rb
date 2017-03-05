require 'hg/redis'

# Enables temporary storage of an ordered list of unprocessed postbacks for a user.
module Hg
  module Queues
    module Messenger
      class PostbackQueue < Hg::Queues::Queue

      end
    end
  end
end
