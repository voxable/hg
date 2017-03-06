RSpec.shared_examples 'a message processing worker' do
  it "pops the latest unprocessed message from the user's queue" do
    # TODO: two expectations in one it block is poor form
    expect(queue_class).to receive(:new).with(hash_including(user_id: user_id)).and_return(queue)
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

    it 'contains the matched intent'

    it 'contains the matched action'

    it 'contains the matched parameters'
  end

  it 'sends the request to the router'
end
