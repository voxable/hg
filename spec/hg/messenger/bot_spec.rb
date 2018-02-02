require 'rails_helper'

RSpec.describe Hg::Messenger::Bot do
  class FAQBot
    include Hg::Messenger::Bot
  end

  before(:example) do
    allow(Facebook::Messenger::Bot).to receive(:on)
  end

  # Stub an access token on the bot
  def stub_access_token
    allow(FAQBot).to receive(:access_token).and_return('token')
  end

  # Spoof an inbound Facebook message
  #
  # @param message [Hashie::Mash] The inbound (fake) message
  def send_message(message)
    Facebook::Messenger::Bot.trigger(:message, message)
  end

  # Spoof an inbound Facebook postback
  #
  # @param postback [Hashie::Mash] The inbound (fake) postback
  def send_postback(postback)
    # Because the `Facebook::Messenger::Bot` triggers are all loaded when the
    # class is required, we can't really isolate ourselves from
    # Facebook::Messenger::Bot's implementation.
    Facebook::Messenger::Bot.trigger(:postback, postback)
  end

  context 'initializing the router' do
    let(:sender_psid) { '1234' }

    let(:payload) { JSON.generate({foo: 'bar'}) }

    before(:all) do
      FAQBot.initialize_message_handlers
    end

    context 'when postbacks received' do
      let(:postback) {
        postback = Hashie::Mash.new
        postback.sender = {id: sender_psid}
        postback.payload = payload
        postback
      }

      before(:example) do
        allow(FAQBot).to receive(:show_typing)
        allow(FAQBot).to receive(:queue_postback)
      end

      it 'shows a typing indicator to the user' do
        expect(FAQBot).to receive(:show_typing).with(sender_psid)

        send_postback(postback)
      end

      it 'queues the postback for processing' do
        expect(FAQBot).to receive(:queue_postback).with(postback)

        send_postback(postback)
      end

      it 'rescues StandardError' do
        allow(FAQBot).to receive(:queue_postback).and_raise StandardError

        expect(Rails.logger).to receive(:error).twice

        send_postback(postback)
      end
    end

    context 'when messages received' do
      let(:message) {
        message = Hashie::Mash.new
        message.sender = {id: sender_psid}
        message
      }

      before(:example) do
        allow(FAQBot).to receive(:show_typing)
        allow(FAQBot).to receive(:queue_message)
      end

      it 'shows a typing indicator to the user' do
        expect(FAQBot).to receive(:show_typing).with(sender_psid)

        send_message(message)
      end

      it 'queues the message for processing' do
        expect(FAQBot).to receive(:queue_message).with(message)

        send_message(message)
      end

      it 'rescues StandardError' do
        allow(FAQBot).to receive(:queue_message).and_raise StandardError

        expect(Rails.logger).to receive(:error).twice

        send_message(message)
      end
    end
  end

  describe '.init' do
    context 'running associated initializers' do
      before(:example) {
        allow(FAQBot).to receive(:subscribe_to_messages)
        allow(FAQBot).to receive(:initialize_message_handlers)
        allow(FAQBot).to receive(:initialize_get_started_button)
        allow(FAQBot).to receive(:initialize_persistent_menu)
        allow(FAQBot).to receive(:initialize_greeting_text)

        FAQBot.init
      }

      it 'subscribes to messages' do
        expect(FAQBot).to have_received(:subscribe_to_messages)
      end

      it 'initializes message handlers' do
        expect(FAQBot).to have_received(:initialize_message_handlers)
      end

      it 'initializes get started button' do
        expect(FAQBot).to have_received(:initialize_get_started_button)
      end

      it 'initializes persisitent menu' do
        expect(FAQBot).to have_received(:initialize_persistent_menu)
      end

      it 'initializes greeting text' do
        expect(FAQBot).to have_received(:initialize_greeting_text)
      end
    end
  end

  describe '.access_token' do
    it 'defaults to the ENV variable FB_ACCESS_TOKEN' do
      result = FAQBot.access_token

      expect(result).to eq ENV['FB_ACCESS_TOKEN']
    end
  end

  describe '.router' do
    before(:example) do
      stub_access_token
    end

    context 'when no router class is explicitly set' do
      context 'when no nested class Router exists' do
        it 'throws an error' do
          expect {
            FAQBot.router
          }.to raise_error(Hg::NoRouterClassExistsError)
        end
      end

      context 'when a nested class Router does exist' do
        let(:router) { class_double('FAQBot::Router').as_stubbed_const }

        before(:example) do
          # access the let value to instantiate the doubled class constant
          router
        end

        it 'defaults to a nested class called Router' do
          expect(FAQBot.router).to eq(router)
        end
      end
    end

    context 'when router class explicitly set' do
      let(:router) { class_double('FAQBot::CustomRouter') }

      before(:each) do
        FAQBot.router = router
      end

      after(:each) do
        FAQBot.router = nil
      end

      it 'returns the router class' do
        expect(FAQBot.router).to eq(router)
      end
    end
  end

  describe '.user_class' do
    before(:example) do
      stub_access_token
    end

    context 'when no user class is explicitly set' do
      context 'when no global class User exists' do
        it 'throws an error' do
          expect {
            FAQBot.user_class
          }.to raise_error(Hg::NoUserClassExistsError)
        end
      end

      context 'when a global class User does exist' do
        let(:user_class) { class_double('User').as_stubbed_const }

        before(:example) do
          # access the let value to instantiate the doubled class constant
          user_class
        end

        it 'defaults to a global class called User' do
          expect(FAQBot.user_class).to eq(user_class)
        end
      end
    end

    context 'when user class explicitly set' do
      let(:user_class) { class_double('FAQBot::CustomUser') }

      before(:each) do
        FAQBot.user_class = user_class
      end

      after(:each) do
        FAQBot.user_class = nil
      end

      it 'returns the custom user class' do
        expect(FAQBot.user_class).to eq(user_class)
      end
    end
  end

  describe '.show_typing' do
    before(:each) do
      stub_access_token
    end

    it 'shows a typing indicator to the user' do
      expect(Facebook::Messenger::Bot).to receive(:deliver).with(hash_including(sender_action: 'typing_on'), anything)

      FAQBot.show_typing('1234')
    end
  end

  describe '.redis_namespace' do
    it 'generates a redis namespace based on the name of the bot class' do
      expect(FAQBot.redis_namespace).to eq('faq_bots')
    end
  end

  describe '.queue_postback' do
    let(:user_id) { '1234' }
    # This is the actual `Facebook::Messenger::Incoming::Postback` object
    let(:postback_obj) {
      Hashie::Mash.new({sender: { id: user_id }, messaging: raw_postback})
    }
    let(:raw_postback) {{
      'postback' => {
        'payload' => encoded_payload
      }
    }}
    let(:parsed_postback) {{
      'postback' => {
        'payload' => payload
      }
    }}
    let(:payload) {{'foo' => 1}}
    let(:encoded_payload) { JSON.generate(payload) }
    let(:queue) { instance_double('Hg::Queues::Messenger::PostbackQueue') }

    before(:example) do
      allow(Hg::Queues::Messenger::PostbackQueue).to receive(:new).and_return(queue)
      allow(queue).to receive(:push)
      allow(Hg::PostbackWorker).to receive(:perform_async)
    end

    it "stores the postback, with the payload parsed as JSON, on the user's queue of unprocessed postbacks" do
      expect(queue).to receive(:push).with(parsed_postback)

      FAQBot.queue_postback(postback_obj)
    end

    context 'queueing the postback for processing' do
      it 'queues for the correct user' do
        expect(Hg::PostbackWorker).to receive(:perform_async).with(user_id, anything, anything)

        FAQBot.queue_postback(postback_obj)
      end

      it 'queues with the correct Redis namespace'

      it 'queues with the correct bot class' do
        expect(Hg::PostbackWorker).to receive(:perform_async).with(anything, anything, FAQBot.to_s)

        FAQBot.queue_postback(postback_obj)
      end
    end
  end

  describe '.queue_message' do
    let(:user_id) { '1234' }
    let(:message) {
      Hashie::Mash.new({sender: { id: user_id }, messaging: messaging})
    }
    let(:messaging) { Object.new }
    let(:queue) { instance_double('Hg::Queues::Messenger::MessageQueue') }

    before(:example) do
      allow(Hg::Queues::Messenger::MessageQueue).to receive(:new).and_return(queue)
      allow(queue).to receive(:push)
      allow(Hg::MessageWorker).to receive(:perform_async)
    end

    it "stores the message on the user's queue of unprocessed messages" do
      expect(queue).to receive(:push).with(message.messaging)

      FAQBot.queue_message(message)
    end

    context 'queueing the message for processing' do
      it 'queues for the correct user' do
        expect(Hg::MessageWorker).to receive(:perform_async).with(user_id, anything, anything)

        FAQBot.queue_message(message)
      end

      it 'queues with the correct Redis namespace'

      it 'queues with the correct bot class' do
        expect(Hg::MessageWorker).to receive(:perform_async).with(anything, anything, FAQBot.to_s)

        FAQBot.queue_message(message)
      end
    end
  end

  describe '.persistent_menu' do
    it 'yields' do
      expect { |b| FAQBot.persistent_menu(&b) }.to yield_with_no_args
    end
  end

  describe '.enable_input' do
    it 'sets input_disabled to false' do
      FAQBot.enable_input

      expect(FAQBot.instance_variable_get(:@input_disabled)).to eq false
    end
  end

  describe '.nested_menu' do
    let(:title) { 'sometitle' }
    let(:nested_title) { 'nestedtitle' }
    let(:menu_block) {
      {
        foo: 'bar'
      }
    }
    let(:nested_menu_item) {
      {
        title: nested_title,
        type: 'postback',
        payload: JSON.generate(menu_block)
      }
    }
    let(:call_to_actions) {
      {
        title: title,
        type: 'nested',
        call_to_actions: [nested_menu_item]
      }
    }
    it 'adds title and block to call_to_actions' do
      FAQBot.nested_menu(title) do
        FAQBot.nested_menu_item nested_title, payload: menu_block
      end

      expect(FAQBot.instance_variable_get(:@call_to_actions)).to eq [call_to_actions]
    end
  end

  describe '.call_to_action' do
    let(:text) { 'sometext' }

    context 'when no options are specified' do
      it 'adds only the text to content' do
        @result = FAQBot.call_to_action(text)

        expect(@result).to eq({ title: text })
      end
    end

    context 'when options[:to] is specified' do
      let(:options) {
        {
          to: 'SomeChunkClass'
        }
      }

      before(:example) do
        @result = FAQBot.call_to_action(text, options)
      end

      it "sets :type to 'postback'" do
        expect(@result[:type]).to eq 'postback'
      end

      it 'generates JSON payload with options[:to]' do
        expect(JSON.parse(@result[:payload])).to include('action', 'parameters' => {'chunk' => options[:to]})
      end
    end

    context 'when options[:url] is specified' do
      let(:options) {
        {
          url: 'SomeValidURL'
        }
      }

      before(:example) do
        @result = FAQBot.call_to_action(text, options)
      end

      it "sets :type to 'web_url'" do
        expect(@result[:type]).to eq 'web_url'
      end

      it 'sets :url to url' do
        expect(@result[:url]).to eq options[:url]
      end
    end

    context 'when options[:payload] is specified' do
      let(:options) {
        {
          payload: 'SomeChunKlass'
        }
      }

      before(:example) do
        @result = FAQBot.call_to_action(text, options)
      end

      it "sets :type to 'postback'" do
        expect(@result[:type]).to eq 'postback'
      end

      it 'generates JSON payload with options[:to]' do
        expect(JSON.parse(@result[:payload])).to eq options[:payload]
      end
    end
  end

  describe '.menu_item' do
    let(:text) { "It's a Wonderful Title" }
    let(:menu_item) { JSON.generate( title: text )}

    before(:example) do
      allow(FAQBot).to receive(:call_to_action).and_return(menu_item)
      FAQBot.menu_item(text)
    end

    it 'creates call_to_action content' do
      expect(FAQBot).to have_received(:call_to_action)
    end

    it 'adds call_to_action content to @call_to_actions' do
      expect(FAQBot.instance_variable_get(:@call_to_actions)).to include menu_item
    end
  end

  describe '.nested_menu_item' do
    let(:text) { 'SMS' }
    let(:options) {
      { foo: 'bar' }
    }

    it 'is an alias for .call_to_action' do
      expect(FAQBot).to receive(:call_to_action).with(text, options)

      FAQBot.nested_menu_item(text, options)
    end
  end

  describe '.subscribe_to_messages' do
    it 'subscribes to webhook notifications' do
      expect(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)

      FAQBot.subscribe_to_messages
    end
  end

  describe '.initialize_persistent_menu' do
    it 'sets persistent menu with @input_disabled and @call_to_actions' do
      expect(Facebook::Messenger::Profile).to receive(:set).and_return true

      FAQBot.initialize_persistent_menu
    end
  end

  describe '.get_started' do
    let(:to_payload) {
      {
        to: 'thisChunk'
      }
    }
    let(:payload) {
      { foo: 'bar' }
    }

    it 'sets @get_started_content' do
      FAQBot.get_started(payload)

      expect(FAQBot.instance_variable_get(:@get_started_content)).to_not be_nil
    end

    context 'when :to is specified' do
      it 'set display_chunk action with payload' do
        FAQBot.get_started(to_payload)

        expect(FAQBot.instance_variable_get(:@get_started_content)).to include(:get_started => { :payload => {:action => Hg::InternalActions::DISPLAY_CHUNK, :parameters => { :chunk => to_payload[:to]}}})
      end
    end
  end

  describe '.initialize_get_started_button' do
    it 'calls FB::MSGR::Profile#set with @get_started_content' do
      allow(Facebook::Messenger::Profile).to receive(:set)

      FAQBot.initialize_get_started_button

      expect(Facebook::Messenger::Profile).to have_received(:set).with(FAQBot.instance_variable_get(:@get_started_content), access_token: FAQBot.access_token)
    end
  end

  describe '.initialize_greeting_text' do
    it 'sets FB Profile greeting text' do
      expect(Facebook::Messenger::Profile).to receive(:set).and_return true

      FAQBot.initialize_greeting_text
    end
  end

  describe '.greeting_text' do
    let(:text) { double('text') }
    it 'sets @greeting_text with arg' do
      FAQBot.greeting_text(text)

      expect(FAQBot.instance_variable_get(:@greeting_text)).to eq text
    end
  end

  describe '.image_url_base' do
    let(:base) { double('base') }
    it 'sets @image_url_base_portion with arg' do
      FAQBot.image_url_base(base)

      expect(FAQBot.instance_variable_get(:@image_url_base_portion)).to eq base
    end
  end
end
