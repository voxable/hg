module Hg
  # All controllers internal to Hg. These handle the internal routes, like
  # 'Hg::Actions::DISPLAY_CHUNK'.
  module Controllers
    # TODO: Document & test
    class ChunksController < Hg::Controller
      def display_chunk
        # TODO: Shouldn't be constantizing user input. Need a way to sanitize this.
        # Although - payloads shouldn't be something the client is allowed to set, in Messenger.
        chunk_class = Kernel.const_get(params[:chunk])

        respond_with chunk_class
      end
    end
  end
end
