module Hg
  # All controllers internal to Hg. These handle the internal routes, like
  # 'Hg::Actions::DISPLAY_CHUNK'.
  module Controllers
    # TODO: Document & test
    class ChunksController < Hg::Controller
      def display_chunk
        # TODO: Shouldn't be constantizing user input. Need a way to sanitize this.
        # Although - payloads shouldn't be something the client is allowed to set, in Messenger.
        # TODO: Also, use Kernel.const_get https://gist.github.com/Haniyya/0d52fb8ae4c3cb3d46a07fc4180c3303
        chunk_class = Kernel.const_get(params[:chunk])
        respond_with chunk_class, context: {
          user: request.user
        }
      end
    end
  end
end
