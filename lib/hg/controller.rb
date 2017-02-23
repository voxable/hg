module Hg
  # An Hg controller defines a number of handler functions for actions. These
  # are analagous to the concept of "controller actions" in Rails.
  class Controller
    # Create a new instance of Controller.
    #
    # @param params [Hash] The parameters for the request.
    def initialize(params: {})
      @params = params
    end
  end
end
