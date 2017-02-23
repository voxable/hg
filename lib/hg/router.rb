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
  #
  # ## Creating a router
  #
  # Add a router to your bot by subclassing `Hg::Router`:
  #
  #   class PizzaBotRouter < Hg::Router; end
  #
  # ### Adding routes
  #
  # You can add a route for an action with the `action` method:
  #
  #   class PizzaBotRouter < Hg::Router
  #     action 'orderPizza', PizzaOrdersController, :create
  #   end
  #
  #  Here, we're specifying that the `orderPizza` action should map to the
  # `PizzaOrdersController`'s `create` handler method.
  #
  #  Note that it's probably a good idea to store your action names as constants.
  #
  # ## The route map
  #
  # The routes map is a `Hashie::Mash` with action names as keys, pointing at
  # `Hashie::Mash` values with the following structure:
  #
  #   {
  #     controller: PizzaOrderController,
  #     handler: :create
  #   }
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
        @routes[action_name] = Hashie::Mash.new
        @routes[action_name].controller = controller
        @routes[action_name].handler = handler_method_name
      end
    end
  end
end
