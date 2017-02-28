require 'support/rails_helper'

RSpec.describe Hg::MessageWorker, type: :worker do
  let(:user_id) { '1' }
  # TODO: likely need a message factory
  let(:message) {
    Hashie::Mash.new({
      sender: {id: user_id}
    })
  }
  let(:message_store) { class_double('Hg::MessageStore').as_stubbed_const }
  let(:valid_args) { [user_id, 'faq_bots'] }

  before(:example) do
    allow(message_store).to receive(:fetch_message_for_user).and_return(message)
  end

  it "pops the latest unprocessed message from the user's queue" do
    expect(Hg::MessageStore).to receive(:fetch_message_for_user).with(user_id, anything)

    subject.perform(*valid_args)
  end

  context "when a message is present on the user's unprocessed message queue" do
    let(:message) { Hashie::Mash.new() }
    let(:api_ai_client) { instance_double('Hg::ApiAiClient') }

    before(:example) do
      allow(Hg::MessageStore).to receive(:fetch_message_for_user).and_return(message)
      allow(Hg::ApiAiClient).to receive(:new).and_return(api_ai_client)
    end

    it 'fetches the associated user' do

    end

    it 'sends the message to API.ai for parsing' do

    end

    context 'when the message is understood by the API.ai agent' do
      it "passes a request to the bot's router"

      context 'constructing the request object' do
        it 'contains the user representing the sender'

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
