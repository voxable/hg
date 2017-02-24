require 'support/rails_helper'

describe Hg::Bot do
  class FAQBot
    include Hg::Bot
  end

  before(:example) do
    allow(Facebook::Messenger::Bot).to receive(:on)
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
    Facebook::Messenger::Bot.trigger(:postback, postback)
  end

  context 'initializing the router' do
    let(:sender_psid) { '1234' }

    let(:payload) { JSON.generate({foo: 'bar'}) }

    let(:message) {
      message = Hashie::Mash.new
      message.sender = {id: sender_psid}
      message
    }

    let(:postback) {
      postback = Hashie::Mash.new
      postback.sender = {id: sender_psid}
      postback.payload = payload
      postback
    }

    before(:all) do
      FAQBot.initialize_router
    end

    before(:example) do
      # Because the `Facebook::Messenger::Bot` triggers are all loaded when the
      # class is required, we can't really isolate ourselves from Facebook::Messenger::Bot's
      # implementation.

      allow(FAQBot).to receive(:show_typing)
    end

    context 'when postbacks received' do
      it 'shows a typing indicator to the user' do
        expect(FAQBot).to receive(:show_typing).with(sender_psid)

        send_postback(postback)
      end

      it 'queues the postback for processing'
    end

    context 'when messages received' do
      it 'shows a typing indicator to the user'

      it 'queues the message for processing'
    end
  end

  describe '#show_typing' do
    it 'shows a typing indicator to the user'
  end
end
