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
  #     action 'orderPizza', controller: PizzaOrdersController, with: :create
  #   end
  #
  #  Here, we're specifying that the `orderPizza` action should map to the
  # `PizzaOrdersController`'s `create` handler method.
  #
  #  Note that it's probably a good idea to store your action names as constants.
  #
  # ## The route map
  #
  # The routes map is a hash with action names as keys, pointing at
  # nested hash values with the following structure:
  #
  #   {
  #     controller: PizzaOrderController,
  #     handler: :create
  #   }
  #
  # ## Routing
  #
  # The router will map an inbound `request` to the appropriate handler method.
  # `request` objects take the following form:
  #
  #  request = {
  #     action: 'orderPizza',
  #     parameters: {
  #       size: 'large',
  #       toppings: ['pepperoni', 'sausage']
  #     }
  #  }
  #
  # Passing a `request` to `handle` directly off the bot's router class will
  # call the action's matching handler method on its controller class:
  #
  #   PizzaBotRouter.handle(request) # => PizzaOrderController.call(:create)
  class Router
    # Error thrown when an action isn't recognized by the router.
    class ActionNotRegisteredError < StandardError
      def initialize(action)
        super("No route registered for action #{action}")
      end
    end

    class << self
      # The actions used internally by Hg.
      INTERNAL_ROUTES = {
        Hg::InternalActions::DISPLAY_CHUNK => {
          controller: Hg::Controllers::ChunksController,
          handler: :display_chunk
        }
      }

      # Create a new class instance variable `routes` on any subclasses.
      def inherited(subclass)
        # Default routes to new hash.
        subclass.instance_variable_set(:@routes, {})

        # TODO: Need to figure this out.
        # Since the class itself is the router, make it immutable for thread-safety.
        # subclass.freeze
      end

      # @return [Hash] The routes map.
      def routes
        @memoized_routes ||= INTERNAL_ROUTES.merge(@routes)
      end

      # Add the action to the routes map.
      #
      # @param action_name [String, Symbol] The name of the action to be matched by the router.
      # @param controller [Class] The class of the controller which contains this
      #   action's handler method.
      # @param with[Symbol] The name of the handler method on the
      #   controller class for this action.
      def action(action_name, controller:, with:)
        handler_method_name = with

        @routes[action_name] = {
          controller: controller,
          handler: handler_method_name
        }
      end

      # Add a route for an action from within a `controller` block.
      #
      # @param action_name [String, Symbol] The name of the action to be matched by the router.
      # @param handler_method_name [Symbol] The name of the handler method on the
      #   controller class for this action.
      def handler(action_name, handler_method_name)
        # TODO: BUG Thread.current isn't going to work in case of multiple routers
        # Needs to be a concurrent object, or dry-ruby_configurable
        action(action_name,
               controller: Thread.current[:current_controller],
               with: handler_method_name)
      end

      def controller(controller_class, &block)
        Thread.current[:current_controller] = controller_class

        yield
      end

      # Handle an inbound request by finding its matching handler method and
      # executing it.
      #
      # @param request [Hash] The inbound request.
      def handle(request)
        # Don't use the router if a route has already been specified.
        unless route = request.route
          begin
            route = routes.fetch(request.action)
            request.route = route

            handler_name = route[:handler]

            controller_for_request = route[:controller].new(
              request:      request,
              router:       self,
              handler_name: handler_name
            )
            controller_for_request.process_action(handler_name)
          rescue KeyError
            if request.fulfillment['speech'].empty? &&
               request.fulfillment['messages'].empty?
              raise ActionNotRegisteredError.new(request.action)
            else
              Hg::Dialogflow::Fulfillment::Messenger::Responder
                .new(request).respond
            end
          end
        end
      end

      # Set up a handler for the default action.
      #
      # @param controller [Class] The class of the controller which contains the
      #   default action's handler method.
      # @param handler_method_name [Symbol] The name of the handler method on the
      #   controller class for the default action.
      def default(controller, handler_method_name)
        action Hg::InternalActions::DEFAULT,
               controller: controller,
               with: handler_method_name
      end
    end
  end
end
