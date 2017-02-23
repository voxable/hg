require 'support/rails_helper'

describe Hg::Controller do
  class OrdersController < Hg::Controller; end

  class BotUser; end

  let(:request) {{
    parameters: {
      toppings: ['cheese', 'pepperoni']
    },
    user: BotUser.new
  }}

  before(:example) do
    @controller_instance = OrdersController.new(request: request)
    @params = Hashie::Mash.new(request[:parameters])
  end

  describe '#initialize' do
    it "sets the params instance variable to the value of the request's params" do
      expect(@controller_instance.instance_variable_get(:@params)).to eq(@params)
    end

    it 'can also handle params as parameters key on the request' do
      controller_instance = OrdersController.new(request: {params: request[:parameters]})

      expect(controller_instance.instance_variable_get(:@params)).to eq(@params)
    end

    it 'sets the user instance variable' do
      expect(@controller_instance.instance_variable_get(:@user)).to eq(request[:user])
    end

    it 'sets the request instance variable' do
      expect(@controller_instance.instance_variable_get(:@request)).to eq(request)
    end
  end

  describe '#params' do
    it 'returns a `Hashie::Mash`' do
      expect(@controller_instance.params).to be_a(Hashie::Mash)
    end

    it 'is aliased to #parameters' do
      expect(@controller_instance.parameters).to eq(@controller_instance.params)
    end
  end

  describe '#respond' do
    # See https://github.com/rspec/rspec-mocks/issues/1076 (it really is a bug)
    # If we try to use a class_double here, it'll throw an error when we attempt
    # to create an expectation on deliver (Missing required keyword arguments: access_token)
    # TODO: file a bug on rspeck-mocks about the above
    let(:messenger_api_client) { double('Facebook::Messenger::Bot') }

    before(:each) do
      Facebook::Messenger::Bot = messenger_api_client
    end

    context 'when the first argument is a string' do
      let(:message_text) { 'hullo' }
      let(:recipient_id) { '1234' }
      let(:user) { double('User', facebook_psid: recipient_id) }

      let(:message) {{
        message: {
          text: message_text,
        }
      }}

      before(:each) do
        allow(@controller_instance).to receive(:user).and_return(user)
      end

      it 'delivers the argument as a text message' do
        expect(messenger_api_client).to receive(:deliver).with(
          hash_including(message), anything)

        @controller_instance.respond(message_text)
      end

      it 'delivers the text message to the user' do
        expect(messenger_api_client).to receive(:deliver).with(
          hash_including({recipient: {id: user.facebook_psid}}), anything)

        @controller_instance.respond('Hello, world.')
      end
    end

    context 'when the first argument is a chunk class' do
      it 'delivers the chunk to the user'

      it 'passes the second argument to the chunk as context'
    end
  end
end
