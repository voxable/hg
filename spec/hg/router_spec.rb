require 'support/rails_helper'

describe Hg::Router do
  describe '.action' do
    ACTION_NAME = 'showRecipe'

    let(:action_name) { ACTION_NAME }

    class RecipesController; end

    class RouterWithSingleAction < Hg::Router
      action ACTION_NAME, RecipesController, :show
    end

    it 'adds the handler to the routes map' do
      expect(RouterWithSingleAction.instance_variable_get(:@routes)).to respond_to(action_name)
    end

    it 'adds the controller class to the routes map for the specified action'

    it 'adds the controller handler method to the routes map for the specified action'
  end

  describe '.routes' do
    it 'allows accessing routes as methods'

    it 'allows accessing routes as strings'

    it 'allows accessing routes as symbols'
  end
end
