module Hg
  module Utils
    module_function

    # Extract options hash from an array argument.
    #
    # @param [Array[Object]] args
    #
    # @api public
    def extract_options(args)
      options = args.last
      options.respond_to?(:to_hash) ? options.to_hash.dup : {}
    end

    def extract_options!(args)
      args.last.respond_to?(:to_hash) ? args.pop : {}
    end
  end
end
