require 'rails_helper'

describe Hg::Queues::Messenger::PostbackQueue do
  let(:id) { '1' }
  let(:name) { 'news_bot' }
  let(:key) { 'news_bot:users:1:messenger:postbacks' }

  it 'generates redis message key and yields' do
    result = Hg::Queues::Messenger::PostbackQueue.new(user_id: id, namespace: name)

    expect(result.instance_variable_get(:@key)).to eq key
  end
end
