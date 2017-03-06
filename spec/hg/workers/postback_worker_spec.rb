require 'support/rails_helper'
require_relative './worker_spec_shared_contexts'

RSpec.describe Hg::PostbackWorker, type: :worker do
  include_context 'with mocked queue' do
    let(:queue_class) { Hg::Queues::Messenger::PostbackQueue }
    let(:queue) { instance_double(queue_class.to_s) }
  end

  include_examples 'a message processing worker'

  context "when a postback is present on the user's unprocessed postback queue" do
    include_context 'when queue has unprocessed message' do
      let(:postback) {}
    end

    before(:example) do
      allow(queue).to receive(:pop).and_return(postback)
      allow(bot_class).to receive(:user_class).and_return(user_class)
      allow(bot_class).to receive(:router).and_return(router_class)
      allow(user_class).to receive(:find_or_create_by).and_return(user)
    end
  end
end
