require 'support/rails_helper'

describe Hg::Controller do
  class OrdersController < Hg::Controller; end

  describe '#initialize' do
    let(:parameters) {{
      size: 'large',
      toppings: ['cheese', 'pepperoni']
    }}

    it 'sets the params instance variable' do
      controller_instance = OrdersController.new(params: parameters)

      expect(controller_instance.instance_variable_get(:@params)).to eq(parameters)
    end
  end

  describe '#params' do
    it 'returns a `Hashie::Mash`'
  end
end
