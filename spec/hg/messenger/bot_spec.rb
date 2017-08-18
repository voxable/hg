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

  describe '.persistent_menu'

  describe '.enable_input' do
    it 'sets input_disabled to false' do
      FAQBot.enable_input

      expect(FAQBot.instance_variable_get(:@input_disabled)).to eq false
    end
  end

  describe '.nested_menu' do
    let(:title) { 'sometitle' }
    let(:menu_block) {
      {
        foo: 'bar'
      }
    }
    let(:call_to_actions) {
      {
        title: title,
        type: 'nested',
        call_to_actions: [menu_block]
      }
    }
    it 'adds title and block to call_to_actions' do
      FAQBot.nested_menu(title) do
        menu_block
      end

      expect(FAQBot.instance_variable_get(:@call_to_actions)).to eq [call_to_actions]
    end
  end

  describe '.menu_item'

  describe '.nested_menu_item'

  describe '.subscribe_to_messages'

  describe '.initialize_persistent_menu'

  describe '.call_to_action'

  describe '.get_started'

  describe '.initialize_get_started_button'

  describe '.greeting_text'

  describe '.image_url_base'

  describe '.initialize_greeting_text'
end
