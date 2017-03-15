module Hg
  # The built-in actions used by Hg internally.
  # TODO: Throw a warning in the router if any of these are overwritten.
  module InternalActions
    DISPLAY_CHUNK = 'display_chunk'
    # Message is not recognized by NLU.
    DEFAULT = 'default'
  end
end
