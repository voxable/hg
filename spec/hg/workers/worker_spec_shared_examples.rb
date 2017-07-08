RSpec.shared_examples 'a message processing worker' do
  it 'finds the proper queue' do
    expect(queue_class).to receive(:new).with(hash_including(user_id: user_id)).and_return(queue)

    subject.perform(*valid_args)
  end

  it "pops the latest unprocessed message from the user's queue" do
    expect(queue).to receive(:pop)

    subject.perform(*valid_args)
  end
end

RSpec.shared_examples 'constructing a request object' do
  context 'constructing the request object' do
    it 'fetches or creates the user representing the sender' do
      expect(user_class).to receive(:find_or_create_by).with(facebook_psid: user_id).and_return(user)
      # TODO: Do we need spies to see what's being passed to Hg::Request.new?

      subject.perform(*valid_args)
    end

    before(:each) do
      request = subject.send(:build_payload_request, payload_hash, user)
    end

    it 'contains the matched intent' do
      expect(request.action).to eq payload_hash['action']
      subject.perform(*valid_args)
    end

    it 'contains the matched action' do
      expect(request.intent).to eq payload_hash['intent']
      subject.perform(*valid_args)
    end

    it 'contains the matched parameters' do
      expect(request.params).to eq payload_hash['params']
      subject.perform(*valid_args)
    end
  end

  it 'sends the request to the router' do
    expect(bot_class.router).to receive(:handle)

    subject.perform(*valid_args)
  end
end
