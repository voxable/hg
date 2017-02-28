require 'support/rails_helper'

describe Hg::Bot do
  class FAQBot
    include Hg::Bot
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
      FAQBot.initialize_router
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
    end
  end

  describe '.access_token' do
    it 'defaults to the ENV variable FB_ACCESS_TOKEN'
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
          }.to raise_error(Hg::NoRouterExistsError)
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
    it "default's the bot's user class to User" #do
      #Hg.user_class = BotUser

      #expect(Hg.user_class).to eq(BotUser)
    #end
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

  describe '.queue_postback' do
    it 'queues the postback'
  end

  describe '.queue_message' do
    it 'queues the message'
  end
end
