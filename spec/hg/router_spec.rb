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

    def process_action(*args); end
  end

  let(:controller_instance) { instance_double('RecipesController', show: nil, process_action: nil) }

  class RouterWithSingleAction < Hg::Router
    action ACTION_NAME, controller: RecipesController, with: HANDLER
  end

  before(:example) do
    allow(RecipesController).to receive(:new).with(any_args).and_return(controller_instance)
  end

  describe '.action' do
    before(:example) do
      @routes = RouterWithSingleAction.instance_variable_get(:@routes)
    end

    it 'adds the handler to the routes map' do
      expect(@routes[action_name]).to be_truthy
    end

    it 'adds the controller class to the routes map for the specified action' do
      expect(@routes[action_name][:controller]).to eq(RecipesController)
    end

    it 'adds the controller handler method to the routes map for the specified action' do
      expect(@routes[action_name][:handler]).to eq(handler)
    end
  end

  describe '.controller' do
    it 'adds the handler to the routes map'
  end

  describe '.routes' do
    it 'returns the route map' do
      expect(RouterWithSingleAction.routes).to_not be_nil
    end

    it 'returns a Hashie::Mash' do
      expect(RouterWithSingleAction.routes).to be_a(Hash)
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
      expect(controller_instance).to receive(:process_action).with(handler)

      RouterWithSingleAction.handle(double('action', action: action_name))
    end

    context "when the action isn't registered in the routes" do
      it 'throws an error' do
        expect { RouterWithSingleAction.handle(double('action', action: 'foo')) }.to raise_error(Hg::Router::ActionNotRegisteredError)
      end
    end
  end
end
