require 'support/rails_helper'

RSpec.describe Hg::MessageWorker, type: :worker do
  BOT_CLASS_NAME = 'NewsBot'

  let(:user_id) { '1' }
  # TODO: likely need a message factory
  let(:message) {
    Hashie::Mash.new({
      sender: {id: user_id}
    })
  }
  let(:bot_class) { class_double(BOT_CLASS_NAME).as_stubbed_const }
  let(:message_store) { class_double('Hg::MessageStore').as_stubbed_const }
  let(:valid_args) { [user_id, 'faq_bots', BOT_CLASS_NAME] }

  before(:example) do
    allow(message_store).to receive(:fetch_message_for_user).and_return({})
    # Access the let variable to instantiate the class double
    bot_class
  end

  it "pops the latest unprocessed message from the user's queue" do
    expect(Hg::MessageStore).to receive(:fetch_message_for_user).with(user_id, anything)

    subject.perform(*valid_args)
  end

  context "when a message is present on the user's unprocessed message queue" do
    let(:text) { 'hi there' }
    let(:message) {
      Hashie::Mash.new({
        sender: { id: user_id },
        text: text
      })
    }
    let(:api_ai_response) { double('api_ai_response', intent: nil, action: nil, parameters: nil)}
    let(:api_ai_client) { instance_double('Hg::ApiAiClient', query: api_ai_response) }
    let(:user_class) { class_double('User').as_stubbed_const }
    let(:user_api_ai_session_id) { 's0m3id' }
    let(:user) { double('user', api_ai_session_id: user_api_ai_session_id) }
    let(:router_class) { double('router', handle: nil) }

    before(:example) do
      allow(Hg::MessageStore).to receive(:fetch_message_for_user).and_return(message)
      allow(Hg::ApiAiClient).to receive(:new).and_return(api_ai_client)
      allow(bot_class).to receive(:user_class).and_return(user_class)
      allow(bot_class).to receive(:router).and_return(router_class)
      allow(user_class).to receive(:find_or_create_by_facebook_psid).and_return(user)
    end

    context 'sending the message to API.ai for parsing' do
      it 'sets the session ID the API.ai session key for the user' do
        expect(Hg::ApiAiClient).to receive(:new).with(user_api_ai_session_id)

        subject.perform(*valid_args)
      end

      it 'sends the message to API.ai for parsing' do
        expect(api_ai_client).to receive(:query).with(text)

        subject.perform(*valid_args)
      end
    end

    context 'when the message is understood by the API.ai agent' do
      it "sends a request to the bot router's handle method" do
        expect(router_class).to receive(:handle)

        subject.perform(*valid_args)
      end

      context 'constructing the request object' do
        it 'fetches or creates the user representing the sender' do
          allow(user_class).to receive(:find_or_create_by_facebook_psid).with(user_id).and_return(user)
          expect(router_class).to receive(:handle).with(hash_including(user: user))

          subject.perform(*valid_args)
        end

        it 'contains the matched intent'

        it 'contains the matched action'

        it 'contains the matched parameters'
      end
    end

    context "when the message isn't understood by the API.ai agent" do
      context 'when the bot has a chunk with a fuzzily-matching keyword' do
        it 'delivers that chunk to the user'
      end

      context 'when the bot does not have a chunk with a fuzzily-matching keyword' do
        it 'delivers the default chunk to the user'
      end
    end
  end

  context "when no messages are present on the user's unprocessed message queue" do
    before(:example) do
      allow(message_store).to receive(:fetch_message_for_user).with(any_args).and_return(Hashie::Mash.new({}))
    end

    it 'does nothing' do
      expect(subject.perform(*valid_args)).to be_nil
    end
  end
end
