require 'support/rails_helper'

describe Hg::Router do
  describe '.action' do
    ACTION_NAME = 'showRecipe'
    HANDLER = :show

    let(:action_name) { ACTION_NAME }
    let(:handler) { HANDLER }

    class RecipesController; end

    class RouterWithSingleAction < Hg::Router
      action ACTION_NAME, RecipesController, :show
    end

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
    it 'allows accessing routes as methods'

    it 'allows accessing routes as strings'

    it 'allows accessing routes as symbols'
  end
end
