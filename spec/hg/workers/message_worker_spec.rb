require 'support/rails_helper'

RSpec.describe Hg::MessageWorker, type: :worker do
  let(:user_id) { '1' }
  let(:valid_args) { [user_id, 'faq_bots'] }

  before(:example) do
    allow(Hg::MessageStore).to receive(:fetch_message_for_user)
  end

  it "pops the latest unprocessed message from the user's queue" do
    expect(Hg::MessageStore).to receive(:fetch_message_for_user).with(user_id, anything)

    subject.perform(*valid_args)
  end

  context "when a message is present on the user's unprocessed message queue"

  context "when no messages are present on the user's unprocessed message queue" do
    it 'throws an error'
  end
end
