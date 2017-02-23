module Hg
  # The router is responsible for routing an incoming action to the appropriate
  # controller:
  #
  #   router.handle({
  #     action: 'orderPizza',
  #     parameters: {
  #       size: 'large',
  #       toppings: ['pepperoni', 'sausage']
  #     }
  #   })
  #
  # The `handle` method expects a `request` object consisting of, at least,
  # `action` and `parameters` keys. Postbacks and raw messages sent through an NLU
  # should use the same set of action and parameter names, so that `request` objects
  # will look the same either way by the time they reach the router.
  class Router
    class << self
      # Create a new class instance variable `routes` on any subclasses.
      def inherited(subclass)
        # Default routes to new `Hashie::Mash`.
        subclass.instance_variable_set(:@routes, Hashie::Mash.new)
      end

      # Add the action to the routes map.
      #
      # @param action_name [String, Symbol] The name of the action to be matched by the router.
      # @param controller [Class] The class of the controller which contains this
      #   action's handler method.
      # @param handler_method_name [Symbol] The name of the handler method on the
      #   controller class for this action.
      def action(action_name, controller, handler_method_name)
        route = @routes[action_name] = Hashie::Mash.new

        #route.controller = controller
        # route
      end
    end
  end
end
