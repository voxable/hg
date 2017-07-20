require 'rails_helper'

describe Hg::Controller do
  class OrdersController < Hg::Controller
    def place
    end
  end

  class BotUser; end

  let(:request) {
    instance_double(
      'Hg::Request',
      parameters: { 'toppings' => ['cheese', 'pepperoni'] },
      user: BotUser.new
    )
  }

  let(:router) {
    class_double('Hg::Router')
  }

  let(:handler_name) { :place }

  before(:example) do
    @controller_instance = OrdersController.new(
      request:      request,
      router:       router,
      handler_name: handler_name
    )
    @params = request.parameters
  end

  describe '#initialize' do
    it "sets the params instance variable to the value of the request's params" do
      expect(@controller_instance.instance_variable_get(:@params)).to eq(@params)
    end

    it 'coerces params to HashWithIndifferentAccess' do
      expect(@controller_instance.instance_variable_get(:@params)).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end

    it 'sets the user instance variable' do
      expect(@controller_instance.instance_variable_get(:@user)).to eq(request.user)
    end

    it 'sets the request instance variable' do
      expect(@controller_instance.instance_variable_get(:@request)).to eq(request)
    end

    it 'sets the router instance variable' do
      expect(@controller_instance.instance_variable_get(:@router)).to eq(router)
    end

    it 'sets the handler_name instance variable' do
      expect(@controller_instance.instance_variable_get(:@handler_name)).to eq(handler_name.to_s)
    end
  end

  describe '#params' do
    it 'is aliased to #parameters' do
      expect(@controller_instance.parameters).to eq(@controller_instance.params)
    end
  end

  describe '#process_action' do
    it 'processes the action'
  end

  describe '#respond' do
    # See https://github.com/rspec/rspec-mocks/issues/1076 (it really is a bug)
    # If we try to use a class_double here, it'll throw an error when we attempt
    # to create an expectation on deliver (Missing required keyword arguments: access_token)
    # TODO: file a bug on rspeck-mocks about the above
    let(:messenger_api_client) { double('Facebook::Messenger::Bot') }

    let(:recipient_id) { '1234' }
    let(:user) { double('User', facebook_psid: recipient_id) }

    before(:example) do
      @old_messenger_bot_class = Facebook::Messenger::Bot
      Facebook::Messenger::Bot = messenger_api_client
      allow(@controller_instance).to receive(:user).and_return(user)
    end

    after(:example) do
      Facebook::Messenger::Bot = @old_messenger_bot_class
    end

    context 'when the first argument is a string' do
      let(:message_text) { 'hullo' }

      let(:message) {{
        message: {
          text: message_text,
        }
      }}

      it 'delivers the argument as a text message' do
        expect(messenger_api_client).to receive(:deliver).with(
          hash_including(message), anything)

        @controller_instance.respond(message_text)
      end

      it 'delivers the text message to the user' do
        expect(messenger_api_client).to receive(:deliver).with(
          hash_including({recipient: {id: user.facebook_psid}}), anything
        )

        @controller_instance.respond('Hello, world.')
      end
    end

    context 'when the first argument is a chunk class' do
      class BotChunk;
        def initialize(*args); end
      end

      let(:chunk_instance) { double('chunk_instance', deliver: nil) }

      before(:each) do
        allow(BotChunk).to receive(:new).and_return(chunk_instance)
      end

      it 'delivers the chunk to the user' do
        expect(BotChunk).to receive(:new).with(
          hash_including({recipient: user.facebook_psid})
        ).and_return(chunk_instance)

        @controller_instance.respond(BotChunk)
      end

      it 'passes the second argument to the chunk as context' do
        context = {foo: 'bar'}

        expect(BotChunk).to receive(:new).with(
          hash_including({context: context})
        ).and_return(chunk_instance)

        @controller_instance.respond(BotChunk, context)
      end
    end
  end

  describe '#performed' do
    it 'returns @performed' do
      result = @controller_instance.performed?

      expect(result).to eq @controller_instance.instance_variable_get(:@performed)
    end
  end

  describe '#halt' do
    it 'sets @performed to true' do
      @controller_instance.halt

      expect(@controller_instance.instance_variable_get(:@performed)).to eq true
    end
  end

  context 'filtering' do
    it 'works with filters'
  end

  describe '#merged_context' do
    it 'generates a merged context'
  end

  describe '#show_typing' do
    it 'sends typing_on to Facebook'
  end

  describe '#flash' do
    it 'sends message for delivery'

    it 'shows typing'
  end

  describe '#prompt' do
    it 'creates new messenger prompt with options'
  end

  describe '#answer' do
    it 'creates new messenger answer'
  end

  describe '#redirect_to' do
    it 'sends request to router with provided params'

    context 'when no intent is provided' do
      it 'substiutes action for intent'
    end
  end

  describe '#logger' do
    it 'exposes Sidekiq logger' do
      expect(Sidekiq::Logging).to receive(:logger)

      @controller_instance.logger
    end
  end

  describe '#t' do
    let(:message_text) { 'sometext' }

    it 'uses I18n' do
      expect(I18n).to receive(:t)

      @controller_instance.t(message_text)
    end
  end
end
