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
      let(:payload) { JSON.generate({foo: 'bar'}) }
      let(:postback) {
        instance_double('Facebook::Messenger::Incoming::Postback',
          sender: { 'id' => user_id },
          payload: payload
        )
      }
      let(:raw_postback) {
        {
          'sender' => {
            'id' => user_id,
          },
          'postback' => {
            'payload' => payload
          }
        }
      }
      let(:valid_args) { [1, 'foo', 'NewsBot'] }
    end

    before(:example) do
      allow(queue).to receive(:pop).and_return(raw_postback, {})
      allow(Facebook::Messenger::Incoming::Postback).to receive(:initialize).and_return(postback)
    end

    include_examples 'constructing a request object'

    it 'adds the payload to the request'
  end

  context "when no postbacks are present on the user's unprocessed postback queue" do
    before(:example) do
      allow(queue).to receive(:pop).and_return({})
    end

    it 'does nothing' do
      expect(subject.perform(*valid_args)).to be_nil
    end
  end
end
