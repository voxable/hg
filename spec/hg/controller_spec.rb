require 'rails_helper'

describe Hg::Controller do
  class OrdersController < Hg::Controller
    before_handler :filter, only: :filtered

    def place; end

    def filtered
      puts 'Not Filtered'
    end

    private

      def filter
        puts 'Filtered' and halt
      end
  end

  class BotUser; end

  let(:recipient_id) { '1234' }
  let(:user) { double('BotUser', facebook_psid: recipient_id) }
  let(:request) {
    instance_double(
      'Hg::Request',
      parameters: { 'toppings' => ['cheese', 'pepperoni'] },
      user: user
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
    # TODO: Test controller not receiving before_handler??
    it 'works with filters'
      # expect(@controller_instance).to receive(:filter)
      #
      # @controller_instance.filtered
  end

  describe '#merged_context' do
    let(:recipient_id) { '1234' }
    let(:user) { double(
      'User',
      facebook_psid: recipient_id
    )}
    let(:params) {
      { 'foo' => 'bar' }
    }
    let(:user_context) {
      {}
    }

    it 'generates a merged context' do
      allow(user).to receive(:context_hash).and_return(params)

      result = @controller_instance.merged_context

      expect(result).to eq params.merge(request.parameters)
    end
  end

  describe '#show_typing' do
    let(:messenger_api_client) { double('Facebook::Messenger::Bot') }
    before(:example) do
      @old_messenger_bot_class = Facebook::Messenger::Bot
      Facebook::Messenger::Bot = messenger_api_client
      allow(@controller_instance).to receive(:user).and_return(user)
    end

    after(:example) do
      Facebook::Messenger::Bot = @old_messenger_bot_class
    end

    it 'sends typing_on to Facebook' do
      expect(messenger_api_client).to receive(:deliver).with hash_including(sender_action: 'typing_on'), anything

      @controller_instance.show_typing
    end
  end

  describe '#flash' do
    let(:messenger_api_client) { double('Facebook::Messenger::Bot') }
    before(:example) do
      @old_messenger_bot_class = Facebook::Messenger::Bot
      Facebook::Messenger::Bot = messenger_api_client
      allow(@controller_instance).to receive(:user).and_return(user)
    end

    after(:example) do
      Facebook::Messenger::Bot = @old_messenger_bot_class
    end

    it 'sends message for delivery' do
      allow(messenger_api_client).to receive(:deliver).and_return true

      expect(@controller_instance).to receive(:respond).with('sometext')

      @controller_instance.flash('sometext')
    end

    it 'shows typing' do
      allow(messenger_api_client).to receive(:deliver).and_return true

      expect(@controller_instance).to receive(:show_typing)

      @controller_instance.flash('sometext')
    end
  end

  describe '#prompt' do
    it 'creates new messenger prompt with options' do
      expect(Hg::Messenger::Prompt).to receive(:new).with hash_including(somekey: 'someval')

      @controller_instance.prompt({somekey: 'someval'})
    end
  end

  describe '#answer' do
    let(:some_msg) {'somemsg'}
    it 'creates new messenger answer' do
      allow(request).to receive(:message).and_return some_msg
      expect(Hg::Messenger::Answer).to receive(:new).with(some_msg, user: user)

      @controller_instance.answer({somekey: 'someval'})
    end
  end

  describe '#ask' do
    let(:prompt) {double('prompt')}
    it 'creates new messenger prompt and asks a question' do
      allow(@controller_instance).to receive(:prompt).and_return(prompt)

      expect(prompt).to receive(:ask).with('What question?', {})

      @controller_instance.ask('What question?')
    end
  end

  describe '#redirect_to' do
    let(:payload) {
      {
        action: 'someaction',
        intent: 'someintent',
        route:  'someroute',
        parameters: 'someparams'
      }
    }
    let(:params_payload) {
      {
        action: 'someaction',
        intent: 'someintent',
        route:  'someroute',
        params: 'someparams'
      }
    }
    let(:router) { class_double(Hg::Router) }

    before(:example) do
      request_stubs
      allow(@controller_instance).to receive(:request).and_return(@request)
      allow(router).to receive(:handle)
    end

    it 'sends request to router' do
      expect(router).to receive(:handle).with(@request)

      @controller_instance.redirect_to(payload)
    end

    it 'works with payload[parameters] or [params]' do
      expect(router).to receive(:handle).with(@request)

      @controller_instance.redirect_to(params_payload)
    end

    context 'when no action is provided' do

      it 'substitutes intent for action'
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

def request_stubs
  @request = double('request')
  allow(@request).to receive(:action=)
  allow(@request).to receive(:intent=)
  allow(@request).to receive(:route=)
  allow(@request).to receive(:parameters=)
  allow(@request).to receive(:params=)
  allow(@request).to receive(:action)
  allow(@request).to receive(:intent)
  allow(@request).to receive(:route)
  allow(@request).to receive(:parameters)
  allow(@request).to receive(:params)
end
