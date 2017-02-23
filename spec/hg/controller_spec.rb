require 'support/rails_helper'

describe Hg::Controller do
  class OrdersController < Hg::Controller; end

  let(:parameters) {{
    size: 'large',
    toppings: ['cheese', 'pepperoni']
  }}

  before(:example) do
    @controller_instance = OrdersController.new(params: parameters)
  end

  describe '#initialize' do
    it 'sets the params instance variable' do
      expect(@controller_instance.instance_variable_get(:@params)).to eq(parameters)
    end
  end

  describe '#params' do
    it 'returns a `Hashie::Mash`' do
      expect(@controller_instance.params).to be_a(Hashie::Mash)
    end
  end
end
