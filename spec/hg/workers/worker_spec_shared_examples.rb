RSpec.shared_examples 'a message processing worker' do
  it "pops the latest unprocessed message from the user's queue" do
    # TODO: two expectations in one it block is poor form
    expect(queue_class).to receive(:new).with(hash_including(user_id: user_id))
    expect(queue).to receive(:pop)

    subject.perform(*valid_args)
  end
end
