require 'support/rails_helper'

describe Hg::Router do
  ACTION_NAME = 'showRecipe'
  HANDLER = :show

  let(:action_name) { ACTION_NAME }
  let(:handler) { HANDLER }

  class RecipesController; end

  class RouterWithSingleAction < Hg::Router
    action ACTION_NAME, RecipesController, :show
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
end
