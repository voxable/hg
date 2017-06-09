module Hg
    module Errors

      class EmptyGalleryError < StandardError
        def message
          'Gallery may not be empty, it must have at least one card.'
        end
      end

  end
end