require 'support/rails_helper'

describe Hg::Router do
  ACTION_NAME = 'showRecipe'
  HANDLER = :show

  let(:action_name) { ACTION_NAME }
  let(:handler) { HANDLER }

  class RecipesController
    # Don't rely on the implementation of `Hg:Controller`. Just accept any args.
    def initialize(*args)
      puts 'hello'
    end

    def show; end
  end

  let(:controller_instance) { instance_double('RecipesController', show: nil) }

  class RouterWithSingleAction < Hg::Router
    action ACTION_NAME, RecipesController, HANDLER
  end

  before(:example) do
    allow(RecipesController).to receive(:new).with(any_args).and_return(controller_instance)
  end

  describe '.action' do
    before(:example) do
      @routes = RouterWithSingleAction.instance_variable_get(:@routes)
    end

    it 'adds the handler to the routes map' do
      expect(@routes).to respond_to(action_name)
    end

    it 'adds the controller class to the routes map for the specified action' do
      expect(@routes[action_name].controller).to eq(RecipesController)
    end

    it 'adds the controller handler method to the routes map for the specified action' do
      expect(@routes[action_name].handler).to eq(handler)
    end
  end

  describe '.routes' do
    it 'returns the route map' do
      expect(RouterWithSingleAction.routes).to_not be_nil
    end

    it 'returns a Hashie::Mash' do
      expect(RouterWithSingleAction.routes).to be_a(Hashie::Mash)
    end
  end

  describe '.handle' do
    context 'initializing controller' do
      let(:request) {{
        action: action_name,
        parameters: {
          ingredient: 'pepper'
        }
      }}

      # TODO: Not entirely sure how to test this
      it 'sets the request' #do
        #expect(RecipesController).to receive(:initialize).with(hash_including({request: request}))

        #RouterWithSingleAction.handle(request)
      #end
    end

    it "calls the handler method on the request's action's controller class" do
      expect(controller_instance).to receive(HANDLER)

      RouterWithSingleAction.handle({action: action_name})
    end
  end
end
